# 🚀 新机安装 Hermes CN Desktop 快速排障指南

## 一、安装顺序（按这个来就不会踩坑）

### 1. Python（必须装对！）
```
❌ 不要用 Microsoft Store 版 Python → 各种 PATH 问题、无权限写文件
✅ 从 https://www.python.org/downloads/ 下载安装
   → 勾选 "Add Python to PATH"
   → 版本选 3.12.x（当前验证过的稳定版）
```
装完验证：
```powershell
python --version          # 必须输出 Python 3.12.x
pip --version             # 必须正常输出
pip install --upgrade pip # 可选，升级到最新
```

### 2. Hermes CN Desktop
```
从官方渠道下载安装包 → 双击安装
安装目录默认: C:\Users\<你>\AppData\Local\Programs\hermes-agent-cn-desktop\
数据目录:     C:\Users\<你>\AppData\Roaming\cn.org.hermesagent.desktop\
```

### 3. Git for Windows（给终端用）
```
从 https://git-scm.com/download/win 下载
安装时选 "Git Bash" → 终端 shell 会用它
```

---

## 二、必改配置（用这个干净模板）

**不要复制老机器的 config.yaml！** 新机路径和 API key 不同，用下面的模板替换同名文件。

用记事本打开，搜 `替换为你的`，把 4 处占位符填上：

```yaml
# === 从这往下粘贴到 config.yaml ===

model:
  provider: deepseek
  default: deepseek-v4-pro
  base_url: https://api.deepseek.com
  api_mode: chat_completions
  api_key: 替换为你的DeepSeek-API-Key

providers:
  deepseek:
    name: DeepSeek
    base_url: https://api.deepseek.com
    api_mode: chat_completions
    transport: openai_chat
    model: deepseek-v4-pro
    models:
      deepseek-v4-flash:
        supports_tools: true
      deepseek-v4-pro:
        supports_tools: true
        supports_reasoning: true
    api_key: 替换为你的DeepSeek-API-Key

terminal:
  backend: local

delegation:
  max_concurrent_children: 3

feishu:
  enabled: true
  app_id: 替换为你的飞书AppID
  app_secret: 替换为你的飞书AppSecret

# === 到此结束，其他保持默认即可 ===
```

文件路径（不要硬编码盘符，用变量）：
```
%APPDATA%\cn.org.hermesagent.desktop\runtime\hermes-home\config.yaml
```
在文件管理器地址栏直接粘贴这行就能打开。

---

## 三、常见踩坑速查

| 症状 | 原因 | 解决 |
|------|------|------|
| `python` 命令跳到 Microsoft Store | 装了 Store 版 Python | 卸载 Store 版 → 去 python.org 重装 → 勾选 PATH |
| Gateway 启动后立即退出 | 端口冲突 或 锁文件残留 | 删掉 `hermes-home/auth.lock`、`gateway-runtime/gateway.lock` |
| 飞书提示 Unauthorized | access_key 同步延迟 | 等 1-2 分钟自动恢复；或者去飞书开放平台重新授权 |
| `git push` 卡住不动 | 全局 credential helper 冲突 | `git push -c credential.helper=` |
| `pip install` 报 SSL 错误 | 国内网络问题 | `pip install xxx -i https://pypi.tuna.tsinghua.edu.cn/simple` |
| 终端里 `ls` `/c/` 等命令不识别 | 没装 Git Bash | 装 Git for Windows |
| `netstat` `taskkill` 乱码 | 中文 Windows 编码 | 用英文或 `chcp 437` 切换代码页 |
| 飞书发消息 Hermes 不回复 🤐 | 见下方「飞书集成排障」 | 逐项排查 🔽 |

---

## 三-B、飞书集成排障（不对话的 7 个检查点）

> 这是新机安装最高频的卡点——config 配对了但飞书死活不回消息。
> 按顺序逐项排查，每项通过后打勾。

### ✅ 检查点 1：飞书应用是否创建正确

打开 [飞书开放平台](https://open.feishu.cn/app) → 找到你的应用 → 确认：

```
应用类型 = 「企业自建应用」（不是「应用商店应用」）
```

### ✅ 检查点 2：应用权限是否开通

应用页面 → 「权限管理」→ 必须开通以下权限：

| 权限 | 用途 |
|------|------|
| `im:message` | 获取用户发送的消息 |
| `im:message:send_as_bot` | 以机器人身份回复消息 |
| `im:chat`（如用群聊） | 获取群聊信息 |

> ⚠️ 权限添加后必须点「批量开通」，然后**发布新版本**才会生效。

### ✅ 检查点 3：事件订阅 URL 是否配置

应用页面 → 「事件订阅」→ 请求地址配置：

```
请求地址：Hermes 启动后控制台会打印（形如 https://xxx/feishu/event）
```

如果 Hermes 还没启动，先跳到检查点 4，配好 config 启动后再回来填。

### ✅ 检查点 4：config.yaml 飞书配置是否正确

确认这 3 个值不是占位符：

```yaml
feishu:
  enabled: true
  app_id: cli_a...          # 飞书应用凭证页的 App ID
  app_secret: xxxxx         # 飞书应用凭证页的 App Secret
```

从哪里获取：
- 飞书开放平台 → 应用 → 「凭证与基础信息」→ 复制 App ID 和 App Secret

### ✅ 检查点 5：白名单用户是否配置

`config.yaml` 同级目录下的 `.env` 文件中：

```
FEISHU_ALLOWED_USERS=ou_xxxxxxxx    # 你的飞书用户 Open ID
```

获取方式：飞书开放平台 → 「成员与部门」→ 找到自己 → 复制 Open ID。

> ⚠️ 如果 `FEISHU_ALLOWED_USERS` 为空或填错，**任何飞书用户发消息都不会被响应**。

### ✅ 检查点 6：应用是否已发布

飞书开放平台 → 应用 → 「版本管理与发布」→ 确认：

```
状态 = 「已发布」（不是「开发中」）
```

没发布的话只有应用管理员能对话，其他人发消息无反应。

### ✅ 检查点 7：access_key 同步延迟（重启后常见）

Hermes 刚启动后 1-2 分钟内，飞书服务端还没同步 access_key，会短暂返回 Unauthorized。

```
现象：重启 Hermes 后发消息不回，等 2 分钟再发就好了。
解决：等。不需要改任何配置。
```

> 如果等了 5 分钟以上仍不行 → 回检查点 4 核对 App ID / App Secret 是否正确。

### 🧪 快速验证

全部配置完成后：

1. 重启 Hermes Desktop
2. 等 1 分钟
3. 在飞书给机器人发 `ping`
4. 回复 `pong` → ✅ 通道正常

---

## 四、装完后的验证清单

```powershell
# 1. Python OK
python --version

# 2. Hermes 进程在跑
tasklist | findstr hermes

# 3. 配置文件存在
dir %APPDATA%\cn.org.hermesagent.desktop\runtime\hermes-home\config.yaml

# 4. 能连 DeepSeek（通过 Hermes 对话界面测试）
```

---

## 五、一键修复脚本（新机通用，不用改路径）

存成 `hermes-fix.bat`，出问题时右键管理员运行：

```batch
@echo off
echo === 清理锁文件 ===
del /f "%APPDATA%\cn.org.hermesagent.desktop\runtime\hermes-home\auth.lock" 2>nul
del /f "%APPDATA%\cn.org.hermesagent.desktop\runtime\hermes-home\gateway-runtime\gateway.lock" 2>nul
del /f "%APPDATA%\cn.org.hermesagent.desktop\runtime\hermes-home\kanban.db.init.lock" 2>nul
del /f "%APPDATA%\cn.org.hermesagent.desktop\runtime\hermes-home\cron\.tick.lock" 2>nul

echo === 杀掉残留进程 ===
taskkill /f /im hermes-agent-cn-desktop.exe 2>nul
taskkill /f /im hermes-agent-cn-runtime-w.exe 2>nul

echo === 3 秒后重新启动 Hermes ===
timeout /t 3
start "" "%LOCALAPPDATA%\Programs\hermes-agent-cn-desktop\hermes-agent-cn-desktop.exe"
echo Done.
pause
```
