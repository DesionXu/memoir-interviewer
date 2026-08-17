/**
 * 原生欢迎页：与网页版欢迎页同款设计（暖色渐变 + 中央徽标 + 大按钮），
 * 提高原生度，降低"纯网页套壳"的审核风险。
 */@Entry
@Component
struct Index {
  build() {
    Column() {
      // 顶部：设置入口
      Row() {
        Blank()
        Text('⚙️ 设置')
          .fontSize(18)
          .fontColor('#8A7A6A')
          .padding(14)
          .onClick(() => {
            this.getUIContext().getRouter().pushUrl({ url: 'pages/Settings' });
          })
      }
      .width('100%')
      .padding({ right: 16, top: 20 })

      Blank()

      // 中央内容
      Column() {
        Text('📖')
          .fontSize(54)
          .width(110)
          .height(110)
          .textAlign(TextAlign.Center)
          .borderRadius(55)
          .backgroundColor('rgba(255,255,255,0.65)')
          .shadow({ radius: 24, color: 'rgba(122,94,58,0.18)', offsetY: 8 })

        Text('回忆录访谈员')
          .fontSize(44)
          .fontWeight(FontWeight.Bold)
          .fontColor('#43332A')
          .letterSpacing(8)
          .margin({ top: 30 })

        Text('把一生的故事，慢慢讲给后人听')
          .fontSize(20)
          .fontColor('#8A7660')
          .letterSpacing(3)
          .margin({ top: 18, bottom: 56 })

        Button('📜 开启回忆录', { type: ButtonType.Capsule })
          .fontSize(26)
          .fontColor(Color.White)
          .height(72)
          .backgroundColor('#8A7A6A')
          .shadow({ radius: 30, color: 'rgba(122,94,58,0.35)', offsetY: 12 })
          .onClick(() => {
            this.getUIContext().getRouter().pushUrl({ url: 'pages/Interview' });
          })

        Row({ space: 18 }) {
          Text('🎤 开口即聊').fontSize(17).fontColor('#6D5A46')
          Text('🔊 温柔朗读').fontSize(17).fontColor('#6D5A46')
          Text('🎙️ 方言陪伴').fontSize(17).fontColor('#6D5A46')
        }
        .padding({ top: 12, bottom: 12, left: 24, right: 24 })
        .borderRadius(999)
        .backgroundColor('rgba(255,255,255,0.55)')
        .margin({ top: 60 })
      }

      Blank()

      Text('为长辈设计的 AI 陪伴访谈 · 免费开源')
        .fontSize(13)
        .fontColor('#A08C74')
        .margin({ bottom: 24 })
    }
    .width('100%')
    .height('100%')
    .linearGradient({
      angle: 160,
      colors: [['#FAF3E7', 0.0], ['#F2E6D3', 0.45], ['#E9D9C0', 1.0]]
    })
  }
}
