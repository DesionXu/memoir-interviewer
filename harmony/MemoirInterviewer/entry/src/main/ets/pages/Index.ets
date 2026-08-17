import { webview } from '@kit.ArkWeb';

/**
 * 主页面：全屏 Web 容器，加载打包在 rawfile 里的欢迎页 index.html
 * （后续步骤：注册 JS 桥接 HarmonyBridge，接入原生语音识别与朗读）
 */
@Entry
@Component
struct Index {
  controller: webview.WebviewController = new webview.WebviewController();

  build() {
    Column() {
      Web({ src: $rawfile('index.html'), controller: this.controller })
        .width('100%')
        .height('100%')
        .javaScriptAccess(true)
        .domStorageAccess(true)
        .fileAccess(true)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F0EB')
  }
}
