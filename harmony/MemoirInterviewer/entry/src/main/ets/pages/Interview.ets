import { webview } from '@kit.ArkWeb';
import { HarmonyBridge } from '../bridge/HarmonyBridge';

/**
 * 访谈页：Web 容器直接加载打包在 rawfile 里的访谈页 memoir.html，
 * 并注册原生桥接 HarmonyBridge（聊天 API 代理 / 原生朗读 / 原生语音识别 /
 * 老照片选图 / 试用埋点）。路由参数 mode：self=本人讲述，child=子女代发起。
 */
@Entry
@Component
struct Interview {
  controller: webview.WebviewController = new webview.WebviewController();
  private bridge: HarmonyBridge | null = null;
  private mode: string = 'self';

  aboutToAppear(): void {
    const context = this.getUIContext().getHostContext();
    try {
      const params = this.getUIContext().getRouter().getParams() as Record<string, string>;
      if (params && params['mode'] === 'child') {
        this.mode = 'child';
      }
    } catch (err) {
      this.mode = 'self';
    }
    if (context) {
      this.bridge = new HarmonyBridge(this.controller, context, this.mode);
    }
  }

  // 必须在 Web 组件控制器挂载完成后注册 JS 代理
  registerProxy(): void {
    if (this.bridge) {
      try {
        this.controller.registerJavaScriptProxy(this.bridge, 'HarmonyBridge', [
          'chat',
          'speak',
          'speakAll',
          'listenStart',
          'listenStop',
          'goHome',
          'getMode',
          'pickPhoto',
          'track',
          'saveState',
          'loadState'
        ]);
      } catch (err) {
        console.error('registerJavaScriptProxy failed');
      }
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
