import { webview } from '@kit.ArkWeb';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { ChatMessage, callChatApi } from '../service/ApiService';
import { TtsService } from '../service/TtsService';
import { AsrService } from '../service/AsrService';

const DOMAIN: number = 0x0000;

/**
 * JS 桥接对象：注册为 window.HarmonyBridge，供打包的网页调用。
 * - chat(messagesJson, maxTokens, temperature, callbackId)：调用 DeepSeek，
 *   结果通过 window.__bridgeResolve/__bridgeReject 异步回传（原始 JSON 字符串）
 * - speak(text)：原生朗读
 * - listenStart()/listenStop()：原生语音识别，结果通过 window.__bridgeOnAsr 回传
 */
export class HarmonyBridge {
  private controller: webview.WebviewController;
  private tts: TtsService = new TtsService();
  private asr: AsrService = new AsrService();

  constructor(controller: webview.WebviewController) {
    this.controller = controller;
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

  // 网页调用：HarmonyBridge.listenStart()
  listenStart(): void {
    this.tts.stop();   // 开始听时停止朗读，避免抢话
    this.asr.start();
  }

  // 网页调用：HarmonyBridge.listenStop()
  listenStop(): void {
    this.asr.stop();
  }
}
