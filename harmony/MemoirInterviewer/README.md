# 📱 回忆录访谈员 · HarmonyOS 版本

混合方案：原生壳（ArkTS/ArkUI）+ Web 容器加载打包的网页访谈应用。

## 目录结构

```
MemoirInterviewer/
├── AppScope/                 # 应用级配置（包名、应用名、图标）
├── entry/
│   └── src/main/
│       ├── ets/
│       │   ├── entryability/EntryAbility.ets   # 入口 Ability
│       │   └── pages/Index.ets                 # 主页面：Web 容器
│       ├── resources/                          # 图标、文案、颜色
│       └── rawfile/                            # 打包的网页文件
├── build-profile.json5      # 构建配置
└── hvigorfile.ts
```

## 开发约定

1. **网页文件同步**：`rawfile/` 里的网页来自仓库根目录的 Web 版本。
   修改根目录 `index.html` / `memoir.html` 后，执行：
   ```bash
   cp index.html memoir.html harmony/MemoirInterviewer/entry/src/main/resources/rawfile/
   ```

2. **包名（bundleName）**：当前为占位符 `com.memoir.interviewer`，
   在 AGC 创建应用后必须改成与 AGC 应用一致的包名（需全局唯一）。

3. **API Key**：网页通过 `window.HarmonyBridge.chat()` 调用原生层，
   Key 由原生层保管（后续步骤实现设置页管理），不会打包进网页。

4. **语音**：鸿蒙 ArkWeb 内核不支持网页版语音识别/朗读，
   由原生层通过 JS 桥接提供（后续步骤实现）。

## 待办（按步骤）

- [x] v0.1 工程骨架 + Web 容器 + 打包网页
- [x] v0.2 原生桥接：chat（API 代理）/ speak（原生朗读）/ listenStart·listenStop（原生语音识别）
- [ ] v0.3 权限弹窗与原生设置页（Key 管理、隐私政策展示）
- [ ] v0.4 联调测试（需 DevEco Studio + 真机/模拟器）
- [ ] v0.5 签名打包上架（材料见仓库 docs/ 目录）

## 配置说明

- `ets/service/Config.ets`：填写 DeepSeek API Key；在线语音需 AGC 开通后可用
- 网页端与原生层通过 `window.HarmonyBridge` 通信，协议见 `ets/bridge/HarmonyBridge.ets`
