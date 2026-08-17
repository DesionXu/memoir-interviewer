import { speechRecognizer } from '@kit.CoreSpeechKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppConfig } from './Config';

const DOMAIN: number = 0x0000;

interface AsrResultJson {
  result?: string;
  final?: boolean;
}

/**
 * 原生语音识别：鸿蒙 ArkWeb 内核不支持网页版 SpeechRecognition，由本服务代劳。
 * 在线识别需 AGC 开通语音识别服务。
 */
export class AsrService {
  private engine: speechRecognizer.SpeechRecognitionEngine | null = null;
  onResult: (finalText: string, interimText: string) => void = () => {
  };
  onEnd: () => void = () => {
  };
  onError: (msg: string) => void = () => {
  };

  async init(): Promise<void> {
    if (this.engine) {
      return;
    }
    const params: speechRecognizer.CreateEngineParams = {
      language: 'zh-CN',
      online: AppConfig.ASR_ONLINE,
      extraParams: { 'recognizerMode': 'long' }
    };
    try {
      this.engine = await speechRecognizer.createEngine(params);
      this.engine.setListener({
        onStart: (sessionId: string) => {
          hilog.info(DOMAIN, 'AsrService', 'onStart: %{public}s', sessionId);
        },
        onResult: (result: speechRecognizer.SpeechRecognitionResult) => {
          this.handleResult(result);
        },
        onEnd: () => {
          this.onEnd();
        },
        onError: (error: speechRecognizer.SpeechError) => {
          this.onError(error.errMsg);
        }
      });
      hilog.info(DOMAIN, 'AsrService', 'ASR engine created');
    } catch (err) {
      const e = err as BusinessError;
      hilog.error(DOMAIN, 'AsrService', 'ASR init failed: %{public}s', e.message);
      this.engine = null;
    }
  }

  private handleResult(result: speechRecognizer.SpeechRecognitionResult): void {
    try {
      const obj = JSON.parse(result.result) as AsrResultJson;
      const text: string = obj.result ?? '';
      const isFinal: boolean = obj.final ?? false;
      if (isFinal) {
        this.onResult(text, '');
      } else {
        this.onResult('', text);
      }
    } catch (err) {
      const e = err as BusinessError;
      hilog.error(DOMAIN, 'AsrService', 'parse result failed: %{public}s', e.message);
    }
  }

  start(): void {
    if (!this.engine) {
      this.onError('语音识别引擎未就绪（在线识别需在 AGC 开通服务）');
      return;
    }
    try {
      this.engine.startListening();
    } catch (err) {
      const e = err as BusinessError;
      this.onError(e.message);
    }
  }

  stop(): void {
    if (this.engine) {
      try {
        this.engine.stopListening();
      } catch (err) {
        const e = err as BusinessError;
        hilog.error(DOMAIN, 'AsrService', 'stop failed: %{public}s', e.message);
      }
    }
  }
}
