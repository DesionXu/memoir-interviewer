/**
 * 应用配置
 * API Key 优先从"设置"页填写（保存在本机 preferences），未设置时使用此默认值。
 */
export class AppConfig {
  // DeepSeek 配置
  static readonly DEFAULT_API_KEY: string = 'YOUR_API_KEY_HERE';
  static readonly API_URL: string = 'https://api.deepseek.com/v1/chat/completions';
  static readonly MODEL: string = 'deepseek-v4-pro';

  // 语音配置：online=1 需要先在 AGC 开通语音合成/识别服务并登录华为账号；
  // 调试期间可临时改为 0（离线模式，设备需已安装系统语音包）。
  static readonly TTS_ONLINE: number = 1;
  static readonly ASR_ONLINE: number = 1;
}
