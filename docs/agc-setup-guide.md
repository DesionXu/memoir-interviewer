# AGC 建应用、签名与上架操作手册

> 前置条件：① 华为开发者账号已实名；② 应用在模拟器/真机联调通过。
> 本手册按操作顺序编写，逐步照做即可。

## 一、在 AGC 创建应用

1. 打开 https://developer.huawei.com/consumer/cn/service/josp/agc/index.html 并登录
2. **我的项目 → 新建项目**（项目名如"回忆录访谈员"）
3. 进入项目 → **添加应用**：
   - 平台：HarmonyOS
   - 应用包名：填写与代码一致的包名 **com.dowson.memoir**（已写入代码，全局唯一）
   - 应用名称："回忆录访谈员"
4. 创建完成后，在 **项目设置 → 常规** 记下 **App ID**

## 二、开通语音服务（在线语音识别/朗读必需）

1. AGC 项目内 → **构建 → API 管理 / 服务列表**，找到并**开通**：
   - **语音识别服务（Speech Recognizer）**
   - **语音合成服务（Text To Speech）**
2. 开通后获取 **API Key**（部分能力自动鉴权，无需配置到代码）
3. 若提示需要配置 `client_id` 等，按 AGC 指引操作
4. 代码侧无需改动：`Config.ets` 里 `TTS_ONLINE=1`、`ASR_ONLINE=1` 即走在线模式

## 三、生成签名证书与 Profile

> 关键：**发布（release）类型的签名不需要绑定设备**。之前报"缺乏设备无法新建 profile"是因为走了调试（debug）类型——调试签名才需要设备 UDID。上架用的是 release 签名。

1. DevEco Studio 打开工程
2. **File → Project Structure → Signing Configs**
3. 勾选 **Automatically generate signature**，登录华为账号
4. 在自动签名弹窗里，如果可以选择 profile 类型：选 **Release（发布）**
   - 若弹窗要求选择 AGC 项目/应用：选择"回忆录访谈员"项目下的 com.dowson.memoir 应用
   - 若仍要求"添加设备"：说明选到了 Debug 类型，返回改选 Release
5. 完成后 `.p12`/`.cer`/`.p7b` 写入 `build-profile.json5` 的 `signingConfigs`
6. **Build → Build App(s)/Hap(s) → release** → 产物 `entry/build/default/outputs/default/*-signed.hap` 或 `.app` 文件

> 若自动签名始终无法生成 release 证书，备选流程：
> DevEco → Build → Generate Key and CSR → 生成证书请求 → 去 AGC → 用户与访问 → 证书管理 → 上传 CSR → 下载发布证书 → 回 DevEco 配置。卡住发截图。

## 四、真机调试（可选）

1. Profile 默认绑定调试设备；真机需在 AGC → 设备管理添加设备 UDID
2. 华为手机开启开发者模式 + USB 调试，连接 Mac
3. 运行前把 `bundleName` 改为 AGC 里注册的包名

## 五、构建发布版本

1. DevEco：**Build → Build App(s)/Hap(s) → 选 release**
2. 产物：`entry/build/default/outputs/default/entry-default-signed.hap`（已签名）
3. 或用命令行（本仓库 `scripts/harmony-build.sh release`，需先在 IDE 完成签名配置）

## 六、提交应用市场审核

1. AGC → 我的应用 → 选中应用 → **分发 → 应用市场**
2. 填写并提交：
   - 应用名称、一句话简介、应用介绍、更新说明（见 `docs/app-description.md`）
   - 图标、截图 3-5 张
   - 隐私政策（见 `docs/privacy-policy.md`，填好姓名/邮箱后上传或提供链接）
   - 软著证书、App 备案号（见 `docs/listing-checklist.md`）
3. 提交后 3-7 个工作日出审核结果；被拒按驳回原因修改后重新提交

## 七、常见问题

| 问题 | 处理 |
|------|------|
| 提示包名已被占用 | 换一个包名（建议含你的昵称/品牌），同时改代码 |
| 在线语音调不通 | 确认 AGC 已开通语音服务；测试设备登录华为账号；先试离线模式（Config.ets 改 0） |
| 签名失败 | 重新执行"自动生成签名"，确认 AGC 应用存在且包名一致 |
| 审核要求测试账号 | 本应用无登录体系，在备注里说明即可 |
