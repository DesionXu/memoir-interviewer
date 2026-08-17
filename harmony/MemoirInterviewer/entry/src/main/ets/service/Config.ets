/**
 * 应用配置
 * 注意：正式打包前请填写 API_KEY；后续版本会提供设置页管理，避免硬编码。
 */
export class AppConfig {
  // DeepSeek 配置
  static readonly API_KEY: string = 'YOUR_API_KEY_HERE';
  static readonly API_URL: string = 'https://api.deepseek.com/v1/chat/completions';
  static readonly MODEL: string = 'deepseek-v4-pro';

  // 语音配置：online=1 需要先在 AGC 开通语音合成/识别服务并登录华为账号；
  // 调试期间可临时改为 0（离线模式，设备需已安装系统语音包）。
  static readonly TTS_ONLINE: number = 1;
  static readonly ASR_ONLINE: number = 1;
}
