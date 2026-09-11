import { webview } from '@kit.ArkWeb';
import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { ChatMessage, callChatApi } from '../service/ApiService';
import { TtsService } from '../service/TtsService';
import { AsrService } from '../service/AsrService';
import { SettingsService } from '../service/SettingsService';
import { AnalyticsService } from '../service/AnalyticsService';
import { PhotoService } from '../service/PhotoService';
import { StateService } from '../service/StateService';
import { ensureMicPermission } from '../service/PermissionUtil';

const DOMAIN: number = 0x0000;

/**
 * JS 桥接对象：注册为 window.HarmonyBridge，供打包的网页调用。
 * - chat(messagesJson, maxTokens, temperature, callbackId)：调用 DeepSeek，
 *   结果通过 window.__bridgeResolve/__bridgeReject 异步回传（原始 JSON 字符串）
 * - speak(text)：原生朗读
 * - listenStart()/listenStop()：原生语音识别（含麦克风权限申请），
 *   结果通过 window.__bridgeOnAsr 回传
 * - getMode(callbackId)：回传发起模式（self=本人讲述 / child=子女代发起）
 * - pickPhoto()：系统选图 → 缩放 → base64，通过 window.__bridgeOnPhoto 回传
 * - track(event, payload)：试用期轻量埋点（PRD-03 L1-L6）
 * - goHome()：返回原生欢迎页
 */
export class HarmonyBridge {
  private controller: webview.WebviewController;
  private context: common.Context;
  private mode: string = 'self';
  private tts: TtsService = new TtsService();
  private asr: AsrService = new AsrService();

  constructor(controller: webview.WebviewController, context: common.Context, mode: string) {
    this.controller = controller;
    this.context = context;
    this.mode = mode === 'child' ? 'child' : 'self';
    SettingsService.init(context);
    AnalyticsService.init(context);
    StateService.init(context);
    this.tts.init();
    this.asr.init();
    this.asr.onResult = (finalText: string, interimText: string) => {
      this.runJs('window.__bridgeOnAsr(' +
        JSON.stringify(JSON.stringify(finalText)) + ', ' +
        JSON.stringify(JSON.stringify(interimText)) + ')');
    };
    this.asr.onEnd = () => {
      this.runJs('window.__bridgeOnAsrEnd()');
    };
    this.asr.onError = (msg: string) => {
      this.runJs('window.__bridgeOnAsrError(' + JSON.stringify(JSON.stringify(msg)) + ')');
    };
  }

  private runJs(script: string): void {
    try {
      this.controller.runJavaScript(script);
    } catch (err) {
      hilog.error(DOMAIN, 'HarmonyBridge', 'runJavaScript failed');
    }
  }

  // 网页调用：HarmonyBridge.chat(messagesJson, maxTokens, temperature, callbackId)
  chat(messagesJson: string, maxTokens: number, temperature: number, callbackId: string): void {
    let messages: ChatMessage[] = [];
    try {
      messages = JSON.parse(messagesJson) as ChatMessage[];
    } catch (err) {
      this.runJs('window.__bridgeReject(' + JSON.stringify(JSON.stringify(callbackId)) + ', ' +
        JSON.stringify(JSON.stringify('消息解析失败')) + ')');
      return;
    }
    callChatApi(messages, maxTokens, temperature).then((rawJson: string) => {
      // 双重 stringify 生成合法的 JS 字符串字面量，网页端 JSON.parse 后得到 OpenAI 格式对象
      this.runJs('window.__bridgeResolve(' + JSON.stringify(JSON.stringify(callbackId)) + ', ' +
        JSON.stringify(JSON.stringify(rawJson)) + ')');
    }).catch((err: Error) => {
      this.runJs('window.__bridgeReject(' + JSON.stringify(JSON.stringify(callbackId)) + ', ' +
        JSON.stringify(JSON.stringify(err.message)) + ')');
    });
  }

  // 网页调用：HarmonyBridge.speak(text)
  speak(text: string): void {
    this.tts.speak(text);
  }

  // 网页调用：HarmonyBridge.listenStart()（先申请麦克风权限再开始识别）
  listenStart(): void {
    this.tts.stop();   // 开始听时停止朗读，避免抢话
    ensureMicPermission(this.context).then((granted: boolean) => {
      if (granted) {
        this.asr.start();
      } else {
        this.runJs('window.__bridgeOnAsrError(' +
          JSON.stringify(JSON.stringify('未获得麦克风权限，请在系统设置中允许')) + ')');
      }
    });
  }

  // 网页调用：HarmonyBridge.listenStop()
  listenStop(): void {
    this.asr.stop();
  }

  // 网页调用：HarmonyBridge.goHome()（返回原生欢迎页）
  goHome(): void {
    router.back();
  }

  // 网页调用：HarmonyBridge.getMode(callbackId) —— 回传发起模式
  getMode(callbackId: string): void {
    this.runJs('window.__bridgeMode(' +
      JSON.stringify(JSON.stringify(callbackId)) + ', ' +
      JSON.stringify(JSON.stringify(this.mode)) + ')');
  }

  // 网页调用：HarmonyBridge.pickPhoto() —— 选老照片，结果经 __bridgeOnPhoto 回传
  pickPhoto(): void {
    PhotoService.pickAndRead().then((dataUrl: string) => {
      this.runJs('window.__bridgeOnPhoto(' + JSON.stringify(JSON.stringify(dataUrl)) + ')');
    }).catch((err: Error) => {
      this.runJs('window.__bridgeOnPhotoError(' + JSON.stringify(JSON.stringify(err.message)) + ')');
    });
  }

  // 网页调用：HarmonyBridge.track(event, payload) —— 试用期轻量埋点
  track(event: string, payload: string): void {
    AnalyticsService.track(event, payload || '');
  }

  // 网页调用：HarmonyBridge.saveState(json) —— 访谈进度持久化（可中断可续接）
  saveState(json: string): void {
    StateService.save(json || '');
  }

  // 网页调用：HarmonyBridge.loadState(callbackId) —— 读取上次访谈进度
  loadState(callbackId: string): void {
    StateService.load().then((json: string) => {
      this.runJs('window.__bridgeState(' +
        JSON.stringify(JSON.stringify(callbackId)) + ', ' +
        JSON.stringify(JSON.stringify(json)) + ')');
    });
  }

  // 网页调用：HarmonyBridge.speakAll(chunksJson) —— 全文逐段朗读
  speakAll(chunksJson: string): void {
    let chunks: string[] = [];
    try {
      chunks = JSON.parse(chunksJson) as string[];
    } catch (err) {
      chunks = [];
    }
    this.tts.speakChunks(chunks);
  }
}
