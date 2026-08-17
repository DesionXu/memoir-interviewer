# DevEco Studio 安装与 v0.4 联调指南

> 目标：在 Mac（Apple Silicon）上把鸿蒙工程跑起来，逐项验证功能，把报错发我迭代修复。
> 当前状态：DevEco Studio 6.1.1 已安装 ✓

## 〇、已安装 DevEco 6.1.1 的注意点

1. 工程按 hvigor 5.0.0 / API 12 配置编写，DevEco 6.x 打开时会提示：
   - **SDK 组件缺失** → 点"下载"，按提示装 API 12 相关组件
   - **迁移工程（Migrate）** → 选择**保持现状/稍后再说**即可，不必升级
   - 若提示缺少 hvigor 相关文件 → 截图发我，我来补
2. 打开方式：**File → Open** 选 `harmony/MemoirInterviewer` 文件夹

## 一、安装 DevEco Studio

1. 打开下载页：https://developer.huawei.com/consumer/cn/download/deveco-studio
2. 选择 **Mac (Apple Silicon)** 版本下载（约 2-4 GB）
3. 打开 dmg 安装到"应用程序"
4. 首次启动：
   - 勾选同意协议
   - 用**华为开发者账号**登录（已注册并实名的那个）
   - 按提示下载 **HarmonyOS SDK**（默认选项全勾）
   - 若提示安装 hvigor/ohpm 组件，全部同意
5. 首次启动较慢，耐心等待"欢迎界面"出现

## 二、打开工程（重要：路径不能有空格）

DevEco/hvigor 不支持含空格的路径，本项目源码位于含空格的目录下，因此请使用**同步脚本**把工程复制到无空格路径再打开：

1. 打开"终端"（Terminal），粘贴执行（注意首尾引号）：

```bash
bash "/Users/hasu/Downloads/project driven by deepseek herness/scripts/deveco-sync.sh"
```

2. 脚本会把工程同步到 `~/DevEcoProjects/MemoirInterviewer`
3. DevEco Studio → **Open** → 选择 `~/DevEcoProjects/MemoirInterviewer`（即 /Users/hasu/DevEcoProjects/MemoirInterviewer）
4. 等待右下角 **Sync**（同步）完成（首次要下载依赖，可能 5-15 分钟）
5. **以后每次我修复代码后**：重新运行同步脚本 → DevEco 点 Sync

> 注意：`~/DevEcoProjects/MemoirInterviewer` 是自动生成的副本，**不要在其中手动改代码**；所有代码修改都在 GitHub 仓库进行。

Sync 时预期情况与处理：

| 情况 | 处理 |
|------|------|
| ~~提示 SDK 版本不匹配~~ | ✅ 已解决：工程已对齐你安装的 HarmonyOS 6.1.1（API 24），不会再有此提示 |
| 提示缺少 hvigor 相关文件 | ✅ 已解决：hvigor/ 配置已补全 |
| 报错 `bundleName 已存在` | 暂时忽略（真机运行才需要改包名，见下） |

## 三、创建模拟器并运行

1. 菜单 **Tools → Device Manager**
2. 左侧 **Local Emulator** → 新建 → 选择 **Phone**（如 Mate 60 Pro 模拟器）
3. 按提示下载模拟器镜像（几个 GB），创建后启动
4. 回到编辑器点顶部 **▶ Run**（或 Ctrl+R / ⌘R）
5. 若提示签名：**File → Project Structure → Signing Configs → 勾选 Automatically generate signature**（登录华为账号自动完成）
6. 应用启动后应看到**原生欢迎页**

## 四、联调测试清单（逐项打勾）

- [ ] 欢迎页正常显示：徽标、标题、副标语、开启回忆录按钮、三个功能标签、右上角 ⚙️ 设置
- [ ] 点"开启回忆录"进入访谈页（网页加载、开场白显示）
- [ ] 点"⚙️ 设置"→ 输入 API Key → 保存 → 显示"已设置"
- [ ] 访谈页发一条文字消息，AI 正常回复（走原生桥接，Key 不经过网页）
- [ ] AI 回复自动朗读（若无声：AGC 未开通在线语音，把 Config.ets 的 TTS_ONLINE 改 0 试离线语音包）
- [ ] 点 🎤 出现麦克风权限弹窗 → 允许 → 说话 → 文字实时出现在输入框
- [ ] 再点 🎤（红色）→ 自动发送
- [ ] 方言下拉切换普通话/粤语/台湾国语
- [ ] 聊几轮后点"生成回忆录"→ 完整生成（标题/概要/目录/正文/页码）
- [ ] 文本框可修改，点"下载回忆录"能保存 txt
- [ ] 访谈页点"← 返回首页"回到原生欢迎页

## 五、真机运行（可选，模拟器通过后再做）

1. 华为手机：设置 → 关于本机 → 连续点版本号开启开发者模式 → 打开 USB 调试
2. USB 连接 Mac，DevEco 弹出设备授权，允许
3. 运行时若报包名冲突：把 `AppScope/app.json5` 的 `bundleName` 改成你自己的（如 `com.dowson.memoir`）
4. 真机验证语音效果更接近真实用户体验

## 六、报错怎么发给我

把以下信息截图/复制发我，我逐个修：
1. 报错弹窗或下方 Build 输出面板的**红色文字**
2. 如果是我写的 ArkTS 文件报错，附上文件名和行号
3. 现象描述（哪一步、点了什么、预期与实际）

预期：第一轮运行大概率有 3-5 个编译报错（ArkTS 严格模式类型问题），都属于正常迭代，修复很快。
