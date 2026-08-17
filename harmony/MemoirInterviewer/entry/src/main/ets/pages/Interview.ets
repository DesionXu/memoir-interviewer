import { webview } from '@kit.ArkWeb';
import { common } from '@kit.AbilityKit';
import { HarmonyBridge } from '../bridge/HarmonyBridge';

/**
 * 访谈页：Web 容器直接加载打包在 rawfile 里的访谈页 memoir.html，
 * 并注册原生桥接 HarmonyBridge（聊天 API 代理 / 原生朗读 / 原生语音识别）。
 */
@Entry
@Component
struct Interview {
  controller: webview.WebviewController = new webview.WebviewController();
  private bridge: HarmonyBridge | null = null;

  aboutToAppear(): void {
    const context = getContext(this) as common.Context;
    this.bridge = new HarmonyBridge(this.controller, context);
  }

  // 必须在 Web 组件控制器挂载完成后注册 JS 代理
  registerProxy(): void {
    if (this.bridge) {
      this.controller.registerJavaScriptProxy(this.bridge, 'HarmonyBridge', [
        'chat',
        'speak',
        'listenStart',
        'listenStop',
        'goHome'
      ]);
    }
  }

  build() {
    Column() {
      Web({ src: $rawfile('memoir.html'), controller: this.controller })
        .width('100%')
        .height('100%')
        .javaScriptAccess(true)
        .domStorageAccess(true)
        .fileAccess(true)
        .onControllerAttached(() => {
          this.registerProxy();
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F0EB')
  }
}
