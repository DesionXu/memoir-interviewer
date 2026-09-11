import { SettingsService } from '../service/SettingsService';
import { AnalyticsService } from '../service/AnalyticsService';
import { pasteboard } from '@kit.BasicServicesKit';

/**
 * 设置页：可选自定义 API Key（留空使用内置 Key）+ 试用数据（PRD-03 L1-L6 轻量埋点查看/导出）+ 隐私说明。
 */
@Entry
@Component
struct Settings {
  @State apiKeyInput: string = '';
  @State savedMask: string = '未设置（使用内置 Key）';
  @State statText: string = '（暂无数据）';
  @State statCount: string = '共 0 条';

  aboutToAppear(): void {
    const context = this.getUIContext().getHostContext();
    if (context) {
      SettingsService.init(context);
      AnalyticsService.init(context);
      SettingsService.getApiKey().then((key: string) => {
        if (key) {
          this.savedMask = '已设置（' + key.slice(0, 6) + '…）';
        }
      });
      this.refreshStats();
    }
  }

  refreshStats(): void {
    AnalyticsService.getAll().then((events: string[]) => {
      const count = (prefix: string): number =>
        events.filter((e: string) => e.split('|')[1] === prefix).length;
      const l1 = count('start_click');
      const l2 = count('first_reply');
      const l3 = count('session_rounds');
      const l4 = count('session_continue');
      const l5 = count('generate_success') + count('generate_fail');
      const l6 = count('readaloud_click') + count('download_click') + count('confirm_click');
      this.statText =
        'L1 启动并点开始：' + l1 + ' 次\n' +
        'L2 首次开口（首答）：' + l2 + ' 次\n' +
        'L3 深入会话（≥5轮）：' + l3 + ' 次\n' +
        'L4 复访续接：' + l4 + ' 次\n' +
        'L5 生成回忆录（成功+失败）：' + l5 + ' 次\n' +
        'L6 朗读/下载/确认：' + l6 + ' 次';
      this.statCount = '共 ' + events.length + ' 条';
    });
  }

  copyStats(): void {
    AnalyticsService.getAll().then((events: string[]) => {
      const text = events.join('\n');
      const data = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text);
      pasteboard.getSystemPasteboard().setData(data).then(() => {
        this.getUIContext().getPromptAction().showToast({ message: '已复制，可粘贴到随访表' });
      });
    });
  }

  clearStats(): void {
    AnalyticsService.clear().then(() => {
      this.refreshStats();
      this.getUIContext().getPromptAction().showToast({ message: '已清空' });
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

          Text('试用数据（漏斗观测）')
            .fontSize(20)
            .fontWeight(FontWeight.Medium)
            .fontColor('#4A3A2C')
            .width('90%')
            .textAlign(TextAlign.Start)
            .margin({ top: 32 })

          Text('按 PRD-03 六层漏斗记录本机行为，仅存本机；每周按此数据填随访表。')
            .fontSize(15)
            .fontColor('#8A7660')
            .width('90%')
            .textAlign(TextAlign.Start)
            .margin({ top: 6, bottom: 10 })

          Text(this.statText)
            .fontSize(17)
            .fontColor('#5A4A3A')
            .lineHeight(30)
            .width('90%')
            .textAlign(TextAlign.Start)
            .padding(16)
            .borderRadius(12)
            .backgroundColor('#FBF8F4')

          Text(this.statCount)
            .fontSize(14)
            .fontColor('#A08C74')
            .width('90%')
            .textAlign(TextAlign.Start)
            .margin({ top: 8 })

          Row({ space: 14 }) {
            Button('复制全部数据')
              .fontSize(17)
              .height(52)
              .backgroundColor('#8A7A6A')
              .fontColor(Color.White)
              .onClick(() => {
                this.copyStats();
              })
            Button('清空')
              .fontSize(17)
              .height(52)
              .backgroundColor('#E9DFD2')
              .fontColor('#5A4A3A')
              .onClick(() => {
                this.clearStats();
              })
          }
          .width('90%')
          .margin({ top: 12 })

          Text('隐私政策')
            .fontSize(20)
            .fontWeight(FontWeight.Medium)
            .fontColor('#4A3A2C')
            .width('90%')
            .textAlign(TextAlign.Start)
            .margin({ top: 32 })

          Text('本应用仅在您点击语音输入时使用麦克风，用于把您的讲述转为文字；您讲述的内容会发送给 AI 服务（DeepSeek）以生成回复。访谈记录与回忆录仅保存在本机，应用不存储、不上传录音和访谈内容。老照片仅在您主动选择后用于回忆录插图与话题引导。详细条款请见应用市场中的《隐私政策》。')
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
