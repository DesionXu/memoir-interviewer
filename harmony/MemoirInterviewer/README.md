# 📱 回忆录访谈员 · HarmonyOS 版本

混合方案：原生壳（ArkTS/ArkUI）+ Web 容器加载打包的网页访谈应用。
已按产品基线文档对齐：HUIYILU-PRD-01《产品界定说明》、PRD-02 V1.1《推进顺序与分工说明》（三角色模型）、PRD-03《用户行为漏斗说明》。

## 目录结构

```
MemoirInterviewer/
├── AppScope/                 # 应用级配置（包名、应用名、图标）
├── entry/
│   └── src/main/
│       ├── ets/
│       │   ├── entryability/EntryAbility.ets   # 入口 Ability（启动埋点）
│       │   ├── bridge/HarmonyBridge.ets        # JS 桥接（chat/speak/ASR/照片/埋点/进度）
│       │   ├── pages/Index.ets                 # 欢迎页：双模式入口（本人讲述 / 子女代发起）
│       │   ├── pages/Interview.ets             # 访谈页：Web 容器（按 mode 路由参数）
│       │   ├── pages/Settings.ets              # 设置页：Key 管理 + 试用数据（L1-L6）+ 隐私说明
│       │   └── service/                        # ApiService/TtsService/AsrService/PhotoService/
│       │                                       # SettingsService/AnalyticsService/StateService
│       ├── resources/                          # 图标、文案、颜色
│       └── rawfile/                            # 打包的网页（memoir.html 访谈页）
├── build-profile.json5      # 构建配置
└── hvigorfile.ts
```

## 产品对齐要点（三份 PRD）

- **三角色双模式（PRD-02 V1.1）**：欢迎页两个入口；子女代发起走受托开场
  「您的孩子托我来听您讲故事」，意愿先行、拒绝即停，页面常驻提示「子女不代答」。
- **访谈规则（PRD-01/02）**：一次一问（全篇单问号、禁"吧？"修辞问句）、顺藤摸瓜、
  徘徊只问不判（往事判断与"讲不讲"意愿）、话题收束并预告下次话题（PRD-03 L4 修复）。
- **老照片（PRD-02 步6）**：📷 系统选图（PhotoViewPicker，无需存储权限）→ 缩放 1280 →
  随消息多模态发给模型读图引导；照片出现在回忆录对应章节标注。
- **可中断可续接（PRD-02）**：会话经 StateService 持久化到本机，再次进入显示续接横幅，
  「继续上次访谈」由 AI 先复述进度再继续（采集期 15-30 分钟短会话节奏）。
- **第一人称零添加成稿（PRD-01 最高优先级）**：只组装原话/删冗余/换第一人称，禁止清单
  （不补对话、场景、心理、评语、过渡），固定开篇「我把这辈子记得的事，讲给家里人听。」，
  宁短勿编；生成后自动做五阶段（童年/离家/成家/育子/晚年）完整性检查，只标未覆盖、绝不补写。
- **交付期（PRD-02 步10-12）**：🔊 朗读全文（原生 TTS 逐段排队自动接续）、✏️ 修改、
  ✅ 老人点头定稿、💾 下载 txt（开放文本格式，长期可读）。
- **试用埋点（PRD-03）**：L1 启动/开始、L2 首答、L3 ≥5 轮、L4 复访续接、L5 生成成败、
  L6 朗读/下载/确认、拒绝事件——仅存本机，设置页「试用数据」可查看统计与复制导出，
  配合每周人工随访表使用。

## 开发约定

1. **网页修改**：访谈页为 `entry/src/main/resources/rawfile/memoir.html`，
   直接修改该文件即可；欢迎页为原生 `pages/Index.ets`（网页版欢迎页仅用于浏览器演示）。
2. **包名（bundleName）**：当前为 `com.dowson.memoir`，已与 AGC 应用一致，勿随意改动。
3. **API Key**：网页通过 `window.HarmonyBridge.chat()` 调用原生层，Key 由原生层保管，
   设置页可自定义（仅存本机）。
4. **语音**：鸿蒙 ArkWeb 内核不支持网页版语音识别/朗读，由原生 CoreSpeechKit 桥接提供。

## 构建

- 已在本机验证：**ArkTS 编译 + HAP 打包成功**（HarmonyOS 6.1.1 / API 24，hvigor 6.24.4，modelVersion 6.0.0）
- 命令行构建：`bash "…/scripts/harmony-build.sh"`（自动注入内置 Key 并注入签名，构建后恢复）
- 或 DevEco Studio 打开工程直接 ▶ Run（IDE 自动处理签名）

## 配置说明

- **内置 API Key（开箱即聊）**：仓库里 `Config.ets` 只存占位符 `YOUR_API_KEY_HERE`；
  真实 Key 在仓库根目录 `config.js` 中，由 `scripts/deveco-sync.sh` / `scripts/harmony-build.sh`
  在同步/构建时自动注入，**不会进入公开仓库**。
- **自定义 Key（可选）**：设置页可填写自定义 Key，优先生效，仅存本机
- `ets/service/Config.ets`：语音在线/离线开关；在线语音需 AGC 开通后可用
- 网页端与原生层通过 `window.HarmonyBridge` 通信，协议见 `ets/bridge/HarmonyBridge.ets`

> ⚠️ 内置 Key 会随安装包分发，技术上可被逆向提取。公开发布前请在 DeepSeek 控制台设置消费上限/告警，并规划收费与防滥用方案。
