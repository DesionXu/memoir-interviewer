import { speechRecognizer } from '@kit.CoreSpeechKit';
import { audio } from '@kit.AudioKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppConfig } from './Config';

const DOMAIN: number = 0x0000;

/**
 * 原生语音识别（API 24 流程）：
 * 1. createEngine + setListener（onResult 收到识别文字）
 * 2. startListening({sessionId, audioInfo}) 后，用 AudioCapturer 采集麦克风 PCM
 * 3. writeAudio 把音频喂给识别引擎
 * 4. 结束：stop 采集 → engine.finish(sessionId) → onComplete 回调
 * 在线识别需 AGC 开通语音识别服务。
 */
export class AsrService {
  private engine: speechRecognizer.SpeechRecognitionEngine | null = null;
  private capturer: audio.AudioCapturer | null = null;
  private sessionId: string = '';
  private running: boolean = false;
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
        onStart: (sessionId: string, eventMessage: string) => {
          hilog.info(DOMAIN, 'AsrService', 'onStart: %{public}s', sessionId);
        },
        onEvent: (sessionId: string, eventCode: number, eventMessage: string) => {
          hilog.info(DOMAIN, 'AsrService', 'onEvent: %{public}s code=%{public}d', sessionId, eventCode);
        },
        onResult: (sessionId: string, result: speechRecognizer.SpeechRecognitionResult) => {
          this.handleResult(result);
        },
        onComplete: (sessionId: string, eventMessage: string) => {
          hilog.info(DOMAIN, 'AsrService', 'onComplete: %{public}s', sessionId);
          this.running = false;
          this.onEnd();
        },
        onError: (sessionId: string, errorCode: number, errorMessage: string) => {
          hilog.error(DOMAIN, 'AsrService', 'onError %{public}d: %{public}s', errorCode, errorMessage);
          this.running = false;
          this.onError(errorMessage);
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
    const text: string = result.result ?? '';
    if (result.isFinal) {
      this.onResult(text, '');
    } else {
      this.onResult('', text);
    }
  }

  async start(): Promise<void> {
    if (!this.engine) {
      this.onError('语音识别引擎未就绪（在线识别需在 AGC 开通服务）');
      return;
    }
    if (this.running) {
      return;
    }
    try {
      // 采集麦克风：16kHz / 单声道 / 16bit PCM
      const capturer = await audio.createAudioCapturer({
        streamInfo: {
          samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_16000,
          channels: audio.AudioChannel.CHANNEL_1,
          sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE,
          encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW
        },
        capturerInfo: {
          source: audio.SourceType.SOURCE_TYPE_MIC,
          capturerFlags: 0
        }
      });
      this.capturer = capturer;
      this.sessionId = 'asr_' + Date.now().toString();
      const sessionId = this.sessionId;
      this.engine.startListening({
        sessionId: sessionId,
        audioInfo: {
          audioType: 'pcm',
          sampleRate: 16000,
          soundChannel: 1,
          sampleBit: 16
        }
      });
      capturer.on('readData', (buffer: ArrayBuffer) => {
        if (this.engine && this.running) {
          this.engine.writeAudio(sessionId, new Uint8Array(buffer));
        }
      });
      await capturer.start();
      this.running = true;
    } catch (err) {
      const e = err as BusinessError;
      hilog.error(DOMAIN, 'AsrService', 'start failed: %{public}s', e.message);
      this.onError('麦克风启动失败：' + e.message);
    }
  }

  stop(): void {
    if (!this.engine || !this.running) {
      return;
    }
    this.running = false;
    if (this.capturer) {
      try {
        this.capturer.stop().then(() => {
        }).catch((err: BusinessError) => {
          hilog.error(DOMAIN, 'AsrService', 'capturer stop failed: %{public}s', err.message);
        });
      } catch (err) {
        const e = err as BusinessError;
        hilog.error(DOMAIN, 'AsrService', 'capturer stop failed: %{public}s', e.message);
      }
    }
    try {
      this.engine.finish(this.sessionId);   // 结束后引擎回调 onComplete
    } catch (err) {
      const e = err as BusinessError;
      hilog.error(DOMAIN, 'AsrService', 'finish failed: %{public}s', e.message);
    }
  }

  shutdown(): void {
    this.running = false;
    if (this.capturer) {
      this.capturer.release().then(() => {
      }).catch((err: BusinessError) => {
        hilog.error(DOMAIN, 'AsrService', 'capturer release failed: %{public}s', err.message);
      });
      this.capturer = null;
    }
    if (this.engine) {
      try {
        this.engine.shutdown();
      } catch (err) {
        const e = err as BusinessError;
        hilog.error(DOMAIN, 'AsrService', 'shutdown failed: %{public}s', e.message);
      }
      this.engine = null;
    }
  }
}
