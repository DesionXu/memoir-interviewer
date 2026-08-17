/**
 * 应用配置
 * BUILTIN_API_KEY：开发者内置 Key（开箱即聊）。仓库里为占位符，
 * 由 scripts/deveco-sync.sh 与 scripts/harmony-build.sh 在构建/同步时
 * 自动用仓库根目录 config.js 中的真实 Key 注入，绝不提交到公开仓库。
 * 用户在设置页填写的自定义 Key 优先生效。
 */
export class AppConfig {
  // DeepSeek 配置
  static readonly BUILTIN_API_KEY: string = 'YOUR_API_KEY_HERE';
  static readonly API_URL: string = 'https://api.deepseek.com/v1/chat/completions';
  static readonly MODEL: string = 'deepseek-v4-pro';

  // 语音配置：online=1 需要先在 AGC 开通语音合成/识别服务并登录华为账号；
  // 调试期间可临时改为 0（离线模式，设备需已安装系统语音包）。
  static readonly TTS_ONLINE: number = 1;
  static readonly ASR_ONLINE: number = 1;
}
