# 上架材料目录（docs/）

| 文件 | 用途 | 状态 |
|------|------|------|
| `listing-checklist.md` | 上架总清单：账号/软著/备案/AGC/签名/审核自查 | 按清单逐项办理 |
| `privacy-policy.md` | 隐私政策全文（应用市场提交用） | 待填开发者姓名、联系邮箱 |
| `permission-declaration.md` | 权限用途说明（审核申诉用） | 已完成 |
| `app-description.md` | 应用名称/简介/更新说明/关键词/截图建议 | 已完成 |
| `soft-copyright-manual.md` | 软著软件说明书 | 待填开发完成日期 |
| `soft-copyright-source-code.txt` | 软著源代码文档（43 页，已生成） | 已生成，可直接打印/导出 PDF |
| `app-icp-filing.md` | App 备案办理指南 | 按指南办理 |
| `agc-setup-guide.md` | AGC 建应用、开通语音、签名、上架提交操作手册 | AGC 阶段使用 |
| `deveco-setup-guide.md` | DevEco 安装 + 联调测试清单 + 已知事项 | 联调时使用 |

## 生成软著源代码文档

代码更新后重新生成（前后各 30 页自动处理，自动检查不含 API Key）：

```bash
python3 scripts/gen_soft_copyright_doc.py
```
