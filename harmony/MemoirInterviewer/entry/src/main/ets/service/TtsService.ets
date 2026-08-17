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
      hilog.info(DOMAIN, 'TtsService', 'TTS engine created');
    } catch (err) {
      const e = err as BusinessError;
      hilog.error(DOMAIN, 'TtsService', 'TTS init failed: %{public}s', e.message);
      this.engine = null;
    }
  }

  speak(text: string): void {
    if (!this.engine || !text) {
      return;
    }
    this.engine.stop();   // 打断上一句
    const params: textToSpeech.SpeakParams = {
      audioType: 'pcm',
      speed: '0.95',      // 语速稍慢，老人听得清
      volume: '1.0'
    };
    this.engine.speak(text, params);
  }

  stop(): void {
    if (this.engine) {
      this.engine.stop();
    }
  }
}
