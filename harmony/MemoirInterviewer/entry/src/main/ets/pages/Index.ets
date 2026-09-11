/**
 * 原生欢迎页：双模式入口（PRD-02 V1.1 三角色模型）
 * - 本人讲述：老人自己发起，AI 直接开场
 * - 子女代发起：受托开场（"您的孩子托我来听您讲故事"），意愿先行、拒绝即停，
 *   子女可陪同但不得代答；访谈全程由子女陪同提醒，讲的是谁，话就是谁的。
 */
@Entry
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
          .margin({ top: 18, bottom: 48 })

        Button('📜 本人讲述', { type: ButtonType.Capsule })
          .fontSize(26)
          .fontColor(Color.White)
          .height(72)
          .width('72%')
          .backgroundColor('#8A7A6A')
          .shadow({ radius: 30, color: 'rgba(122,94,58,0.35)', offsetY: 12 })
          .onClick(() => {
            this.getUIContext().getRouter().pushUrl({ url: 'pages/Interview', params: { mode: 'self' } });
          })

        Text('老人自己发起，直接开始聊')
          .fontSize(15)
          .fontColor('#8A7660')
          .margin({ top: 10 })

        Button('❤️ 子女代发起', { type: ButtonType.Capsule })
          .fontSize(26)
          .fontColor('#FFFFFF')
          .height(72)
          .width('72%')
          .backgroundColor('#B07A62')
          .shadow({ radius: 30, color: 'rgba(176,122,98,0.35)', offsetY: 12 })
          .margin({ top: 30 })
          .onClick(() => {
            this.getUIContext().getRouter().pushUrl({ url: 'pages/Interview', params: { mode: 'child' } });
          })

        Text('想给孙子孙女留一本——由您发起，老人愿意才讲')
          .fontSize(15)
          .fontColor('#8A7660')
          .width('86%')
          .textAlign(TextAlign.Center)
          .margin({ top: 10 })

        Row({ space: 18 }) {
          Text('🎤 开口即聊').fontSize(17).fontColor('#6D5A46')
          Text('🔊 温柔朗读').fontSize(17).fontColor('#6D5A46')
          Text('🖼️ 老照片讲故事').fontSize(17).fontColor('#6D5A46')
        }
        .padding({ top: 12, bottom: 12, left: 24, right: 24 })
        .borderRadius(999)
        .backgroundColor('rgba(255,255,255,0.55)')
        .margin({ top: 44 })
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
