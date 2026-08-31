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

## 三、生成签名证书与 Profile（Release 手动流程，不需要设备）

> DevEco 的"Automatically generate signature"只生成调试证书（需绑定设备）。
> 上架需要**发布（Release）签名**，用手动流程：本地生成密钥 → AGC 换发布证书 → AGC 生成发布 Profile → 回填 DevEco。

**第 1 步：本地生成密钥与证书请求（CSR）**
1. DevEco 菜单：**Build → Generate Key and CSR**
2. 弹窗填写：
   - Key Store File：选一个保存路径（如 `~/Downloads/memoir-release.p12`），点新建
   - Password / Confirm Password：**自定密码**（记下来，如 `memoir123456`）
   - Alias：`memoir`
   - Key Password：同上（勾选与 store 密码一致即可）
   - Validity：默认 25 年
   - 证书信息：First and Last Name 填你的名字拼音/开发者名，其余可留空，Country 填 CN
3. 点 Finish → 生成 `.p12`（密钥库）和 `.csr`（证书请求）两个文件

**第 2 步：AGC 换发布证书（.cer）**
1. AGC 控制台 → 你的项目 → **用户与访问（Users and access）→ 证书管理（Certificate management）**
2. **新增证书** → 上传刚才的 `.csr` 文件 → 证书类型选 **发布（Release）** → 提交
3. 证书列表里找到刚生成的证书 → **下载** `.cer` 文件

**第 3 步：AGC 生成发布 Profile（.p7b）**
1. AGC 控制台 → 项目 → **项目设置 → HAP Provision Profile**（部分版本在"分发"相关菜单下）
2. **添加** → Profile 类型选 **Release** → 选择包名 **com.dowson.memoir** → 选择刚上传的发布证书
3. 生成后**下载** `.p7b` 文件

**第 4 步：回填 DevEco 签名配置**
1. **File → Project Structure（⌘;）→ Signing Configs**
2. **取消勾选** Automatically generate signature（改用手动）
3. 手动填写：
   - Store File：选第 1 步的 `.p12`
   - Store Password：你设的密码
   - Key Alias：`memoir`
   - Key Password：你设的密码
   - Sign Alg：`SHA256withECDSA`
   - Profile File：选第 3 步的 `.p7b`
   - Certpath：选第 2 步的 `.cer`
4. **Apply → OK**

**第 5 步：构建发布包**
1. **Build → Build App(s)/Hap(s) → release**
2. 产物：`entry/build/default/outputs/default/` 下的 `.app` 或 `-signed.hap`（签名版）
3. 用这个包在 AGC 上传提审

> 模拟器本地体验可跳过以上全部：未签名 HAP 可直接 `hdc install`（已实测）。

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
