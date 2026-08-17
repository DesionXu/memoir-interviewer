# 上架清单与流程（华为应用市场）

> 状态：逐步办理中。每完成一项在 [ ] 里打 x。

## 一、账号与资质（个人开发者）

- [ ] 注册华为开发者账号（https://developer.huawei.com/consumer/cn/）
- [ ] 完成个人实名认证（身份证，一般 1 个工作日内）
- [ ] 计算机软件著作权（软著）登记
  - 办理渠道：中国版权保护中心官网（https://register.ccopyright.com.cn/）自办，或代办机构
  - 周期：自办约 30-60 天（可加急）；代办一般 1-2 个月出证
  - 材料：申请表、用户手册（本项目的 README/使用说明）、源程序（前后各 30 页、每页 50 行，共 60 页；本项目代码量足够，可直接取 index.html/memoir.html/server.js/ArkTS 源码排版）
  - ⚠️ 华为应用市场多数类目要求提供软著，建议现在就启动办理
- [ ] App 备案（ICP 备案）
  - 2023 年起新上架 App 需完成备案；通过接入服务商（如华为云）或华为开发者平台指引办理
  - 需先有服务器/域名信息或通过华为侧辅助材料办理

## 二、应用开发与配置

- [ ] DevEco Studio 安装（Mac Apple Silicon 版）
- [ ] 打开工程 harmony/MemoirInterviewer 并 Sync 通过
- [ ] 填写 entry/src/main/ets/service/Config.ets 中的 API_KEY
- [ ] 包名确认：AGC 创建应用后，把 AppScope/app.json5 的 bundleName 改成与 AGC 一致的唯一包名（当前占位 com.memoir.interviewer）
- [ ] 更换正式应用图标（当前为占位图，建议 1024×1024 设计稿）
- [ ] 模拟器/真机联调：语音识别、朗读、聊天、回忆录全链路

## 三、AGC（AppGallery Connect）与签名

- [ ] AGC 创建应用（https://developer.huawei.com/consumer/cn/service/josp/agc/index.html）
  - 创建项目 → 添加应用 → 填写与代码一致的包名
- [ ] 开通所需服务：语音合成、语音识别（Core Speech Kit）——在线语音必须开通
- [ ] 生成签名证书与 Profile（DevEco：File → Project Structure → Signing Configs → 自动签名，登录华为账号一键生成）
- [ ] 构建 Release 版本（Build → Build App(s)/Hap(s) → release）

## 四、提交审核材料

- [ ] 应用名称、图标、一句话简介（见 docs/app-description.md）
- [ ] 应用介绍、更新说明（见 docs/app-description.md）
- [ ] 隐私政策（见 docs/privacy-policy.md，需补充开发者姓名与联系邮箱，并上传/提供访问链接）
- [ ] 权限说明（见 docs/permission-declaration.md，用于审核申诉时说明）
- [ ] 截图 3-5 张（见 docs/app-description.md 截图建议）
- [ ] 软著证书扫描件
- [ ] App 备案号
- [ ] 测试账号（若审核需要登录）

## 五、高频拒审原因（提前自查）

1. **隐私合规**：弹窗说明麦克风用途；隐私政策与实际收集一致；不得违规收集无关权限
2. **功能完整性**：避免被认定"纯网页套壳"——本项目含原生欢迎页/设置页/原生语音，可重点说明原生能力
3. **名称与图标**：名称不得侵权、不得含敏感词；图标清晰合规
4. **内容合规**：AI 生成内容需有内容安全提示（访谈内容涉及个人讲述，无违规风险；如接入在线内容请加"内容由 AI 生成"提示）
5. **账号资质**：软著、备案齐全，个人开发者主体信息一致

## 六、预计时间线

| 事项 | 周期 |
|------|------|
| 账号注册实名 | 1-2 天 |
| DevEco 环境 + 联调 | 3-7 天（与我配合） |
| 软著办理 | 30-60 天（最早启动，可与开发并行） |
| App 备案 | 1-4 周（与软著并行） |
| 审核 | 3-7 个工作日（拒审则再加一轮） |
