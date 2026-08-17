import { webview } from '@kit.ArkWeb';
import { HarmonyBridge } from '../bridge/HarmonyBridge';

/**
 * 主页面：全屏 Web 容器，加载打包在 rawfile 里的欢迎页 index.html，
 * 并注册原生桥接 HarmonyBridge（聊天 API 代理 / 原生朗读 / 原生语音识别）。
 */
@Entry
@Component
struct Index {
  controller: webview.WebviewController = new webview.WebviewController();
  private bridge: HarmonyBridge | null = null;

  aboutToAppear(): void {
    this.bridge = new HarmonyBridge(this.controller);
    this.controller.registerJavaScriptProxy(this.bridge, 'HarmonyBridge', [
      'chat',
      'speak',
      'listenStart',
      'listenStop'
    ]);
  }

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
