import { SettingsService } from '../service/SettingsService';

/**
 * 设置页：可选自定义 API Key（留空使用内置 Key）+ 精简隐私说明 + 关于信息。
 */
@Entry
@Component
struct Settings {
  @State apiKeyInput: string = '';
  @State savedMask: string = '未设置（使用内置 Key）';

  aboutToAppear(): void {
    const context = this.getUIContext().getHostContext();
    if (context) {
      SettingsService.init(context);
      SettingsService.getApiKey().then((key: string) => {
        if (key) {
          this.savedMask = '已设置（' + key.slice(0, 6) + '…）';
        }
      });
    }
  }

  build() {
    Column() {
      Row() {
        Text('← 返回')
          .fontSize(20)
          .fontColor('#8A7A6A')
          .padding(12)
          .onClick(() => {
            this.getUIContext().getRouter().back();
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
          Text('自定义 API Key（可选）')
            .fontSize(20)
            .fontWeight(FontWeight.Medium)
            .fontColor('#4A3A2C')
            .width('90%')
            .textAlign(TextAlign.Start)

          Text('留空即可直接使用应用内置 Key 聊天；填写后优先生效，仅保存在本机。')
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
                this.getUIContext().getPromptAction().showToast({ message: '请输入 API Key' });
                return;
              }
              SettingsService.setApiKey(key).then(() => {
                this.savedMask = '已设置（' + key.slice(0, 6) + '…）';
                this.apiKeyInput = '';
                this.getUIContext().getPromptAction().showToast({ message: '已保存' });
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
