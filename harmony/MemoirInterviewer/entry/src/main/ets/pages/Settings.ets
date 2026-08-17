import { common } from '@kit.AbilityKit';
import { promptAction, router } from '@kit.ArkUI';
import { SettingsService } from '../service/SettingsService';

const PLACEHOLDER_KEY: string = 'YOUR_API_KEY_HERE';

/**
 * 设置页：管理 DeepSeek API Key（仅存本机）+ 精简隐私说明 + 关于信息。
 */
@Entry
@Component
struct Settings {
  @State apiKeyInput: string = '';
  @State savedMask: string = '未设置';

  aboutToAppear(): void {
    const context = getContext(this) as common.Context;
    SettingsService.init(context);
    SettingsService.getApiKey().then((key: string) => {
      if (key && key !== PLACEHOLDER_KEY) {
        this.savedMask = '已设置（' + key.slice(0, 6) + '…）';
      }
    });
  }

  build() {
    Column() {
      Row() {
        Text('← 返回')
          .fontSize(20)
          .fontColor('#8A7A6A')
          .padding(12)
          .onClick(() => {
            router.back();
          })
        Blank()
        Text('设置')
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .fontColor('#4A3A2C')
        Blank()
        Text('返回')
          .fontSize(20)
          .fontColor(Color.Transparent)
          .padding(12)
      }
      .width('100%')
      .padding({ top: 16, bottom: 8 })

      Scroll() {
        Column() {
          Text('DeepSeek API Key')
            .fontSize(20)
            .fontWeight(FontWeight.Medium)
            .fontColor('#4A3A2C')
            .width('90%')
            .textAlign(TextAlign.Start)

          Text('用于 AI 访谈对话与回忆录生成，仅保存在本机，不会上传。')
            .fontSize(15)
            .fontColor('#8A7660')
            .width('90%')
            .textAlign(TextAlign.Start)
            .margin({ top: 6, bottom: 12 })

          TextInput({ placeholder: '粘贴你的 API Key（sk-…）', text: this.apiKeyInput })
            .type(InputType.Password)
            .width('90%')
            .height(56)
            .fontSize(17)
            .onChange((value: string) => {
              this.apiKeyInput = value;
            })

          Text('当前状态：' + this.savedMask)
            .fontSize(16)
            .fontColor('#7A6A58')
            .width('90%')
            .textAlign(TextAlign.Start)
            .margin({ top: 10 })

          Button('保 存', { type: ButtonType.Capsule })
            .fontSize(22)
            .fontColor(Color.White)
            .height(60)
            .width('90%')
            .backgroundColor('#7AA05C')
            .margin({ top: 18 })
            .onClick(() => {
              const key = this.apiKeyInput.trim();
              if (!key) {
                promptAction.showToast({ message: '请输入 API Key' });
                return;
              }
              SettingsService.setApiKey(key).then(() => {
                this.savedMask = '已设置（' + key.slice(0, 6) + '…）';
                this.apiKeyInput = '';
                promptAction.showToast({ message: '已保存' });
              });
            })

          Text('隐私政策')
            .fontSize(20)
            .fontWeight(FontWeight.Medium)
            .fontColor('#4A3A2C')
            .width('90%')
            .textAlign(TextAlign.Start)
            .margin({ top: 32 })

          Text('本应用仅在您点击语音输入时使用麦克风，用于把您的讲述转为文字；您讲述的内容会发送给 AI 服务（DeepSeek）以生成回复。访谈记录与回忆录仅保存在本机，应用不存储、不上传录音和访谈内容。详细条款请见应用市场中的《隐私政策》。')
            .fontSize(16)
            .fontColor('#6D5A46')
            .lineHeight(26)
            .width('90%')
            .textAlign(TextAlign.Start)
            .margin({ top: 10 })

          Text('回忆录访谈员 v1.0.0')
            .fontSize(15)
            .fontColor('#A08C74')
            .margin({ top: 32, bottom: 24 })
        }
        .width('100%')
      }
      .layoutWeight(1)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F0EB')
  }
}
