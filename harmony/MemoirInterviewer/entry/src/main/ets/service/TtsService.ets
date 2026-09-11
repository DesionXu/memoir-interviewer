import { textToSpeech } from '@kit.CoreSpeechKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppConfig } from './Config';

const DOMAIN: number = 0x0000;

/**
 * 原生朗读：鸿蒙 ArkWeb 内核不支持网页 speechSynthesis，由本服务代劳。
 * 在线合成需 AGC 开通；离线合成需设备安装系统语音包。
 */
export class TtsService {
  private engine: textToSpeech.TextToSpeechEngine | null = null;
  private queue: string[] = [];
  private speaking: boolean = false;

  async init(): Promise<void> {
    if (this.engine) {
      return;
    }
    const params: textToSpeech.CreateEngineParams = {
      language: 'zh-CN',
      person: 0,
      online: AppConfig.TTS_ONLINE,
      extraParams: { 'synthesis.echo': '1' }
    };
    try {
      this.engine = await textToSpeech.createEngine(params);
      this.engine.setListener({
        onStart: (requestId: string, response: textToSpeech.StartResponse) => {
        },
        onComplete: (requestId: string, response: textToSpeech.CompleteResponse) => {
          this.speakNext();   // 一段播完自动接下一段（全文朗读）
        },
        onStop: (requestId: string, response: textToSpeech.StopResponse) => {
        },
        onError: (requestId: string, errorCode: number, errorMessage: string) => {
          hilog.error(DOMAIN, 'TtsService', 'speak error %{public}d: %{public}s', errorCode, errorMessage);
          this.speaking = false;
          this.queue = [];
        }
      });
      hilog.info(DOMAIN, 'TtsService', 'TTS engine created');
    } catch (err) {
      const e = err as BusinessError;
      hilog.error(DOMAIN, 'TtsService', 'TTS init failed: %{public}s', e.message);
      this.engine = null;
    }
  }

  private speakNext(): void {
    if (!this.engine) {
      return;
    }
    if (this.queue.length === 0) {
      this.speaking = false;
      return;
    }
    const text = this.queue.shift();
    const params: textToSpeech.SpeakParams = {
      requestId: 'tts_' + Date.now().toString()
    };
    this.speaking = true;
    this.engine.speak(text as string, params);
  }

  speak(text: string): void {
    if (!this.engine || !text) {
      return;
    }
    this.stop();   // 打断上一句
    this.queue = [text];
    this.speakNext();
  }

  // 全文朗读（PRD-02 步10）：逐段排队，一段播完自动接下一段
  speakChunks(texts: string[]): void {
    if (!this.engine || texts.length === 0) {
      return;
    }
    this.stop();
    this.queue = texts.slice();
    this.speakNext();
  }

  stop(): void {
    this.queue = [];
    this.speaking = false;
    if (this.engine) {
      this.engine.stop();
    }
  }
}
