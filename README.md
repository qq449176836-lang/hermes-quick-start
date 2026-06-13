# 🚀 Hermes CN Desktop 一键安装工具包

> Windows 新机 → 5 分钟全自动搞定 Hermes CN Desktop

[![GitHub](https://img.shields.io/badge/GitHub-hermes--quick--start-blue)](https://github.com/qq449176836-lang/hermes-quick-start)

---

## 📦 文件说明

| 文件 | 用途 | 适用场景 |
|------|------|----------|
| **hermes-setup.bat** | 主安装脚本 | 桌面 / 服务器 |
| hermes-fix.bat | 崩溃修复 | 飞书不对话 / 锁文件残留 |
| hermes-install-guide.md | 排障手册 | 安装出问题时查阅 |

---

## ⚡ 快速开始

### 桌面用户（有 GUI）

```powershell
powershell -c "iwr -Uri 'https://raw.githubusercontent.com/qq449176836-lang/hermes-quick-start/main/hermes-setup.bat' -OutFile setup.bat; .\setup.bat"
```

### 服务器 / 无人值守（零交互）

```powershell
# 1. 设置环境变量（替换为实际值）
set HERMES_API_KEY=sk-xxx
set HERMES_MODEL=deepseek-v4-pro
set FEISHU_APP_ID=cli_xxx
set FEISHU_APP_SECRET=xxx
set FEISHU_ALLOWED_USERS=ou_xxx

# 2. 静默安装
powershell -c "iwr -Uri 'https://raw.githubusercontent.com/qq449176836-lang/hermes-quick-start/main/hermes-setup.bat' -OutFile setup.bat; .\setup.bat /silent"
```

安装日志在 `%TEMP%\hermes-install.log`。

---

## 🔧 setup.bat 做了什么

| 步骤 | 内容 | 静默模式 |
|------|------|----------|
| 1 | 安装 Python 3.12（winget → 清华镜像） | ✅ 全自动 |
| 2 | 安装 Git for Windows | ✅ 全自动 |
| 3 | 配置 pip 国内镜像 + 安装依赖 | ✅ 全自动 |
| 4 | **下载安装 Hermes CN Desktop** | ✅ 全自动 |
| 5 | 生成 config.yaml（环境变量注入） | ✅ 自动读取 |
| 6 | 生成飞书 .env 白名单 | ✅ 自动读取 |
| 7 | 安装后验证 | ✅ 自动 |

---

## 📋 环境变量模板

创建 `.env` 文件或设置系统环境变量：

```ini
# === DeepSeek API ===
HERMES_API_KEY=sk-你的key
HERMES_MODEL=deepseek-v4-pro
HERMES_PROVIDER=deepseek

# === 飞书集成 ===
FEISHU_APP_ID=cli_xxx
FEISHU_APP_SECRET=xxx
FEISHU_ALLOWED_USERS=ou_xxx

# === 企业代理（可选） ===
HTTP_PROXY=http://proxy.company.com:8080
HTTPS_PROXY=http://proxy.company.com:8080

# === 静默安装（服务器用） ===
SILENT=1
```

---

## 🔄 服务器部署检查清单

```
□ Windows Server 2016+ / Windows 10+
□ 管理员权限（安装 Python/Git 需要）
□ 外网可达（或已配置 HTTP_PROXY）
□ 已获取 DeepSeek API Key
□ 已创建飞书企业自建应用
□ 关闭 Windows Defender 实时保护（安装期间）
```

---

## 🛠️ 出问题了？

```powershell
# 飞书不对话 / 进程崩溃
powershell -c "iwr -Uri 'https://raw.githubusercontent.com/qq449176836-lang/hermes-quick-start/main/hermes-fix.bat' -OutFile fix.bat; .\fix.bat"

# 静默修复
.\fix.bat /silent
```

---

## 📜 许可

MIT License
