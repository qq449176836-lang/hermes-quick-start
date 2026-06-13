# 📘 Hermes CN Desktop 安装排障指南

> 安装出问题时对照查看。日常使用请直接运行 `hermes-setup.bat`。

---

## 一、安装顺序

```
1. Python 3.12  ← setup.bat 自动安装
2. Git          ← setup.bat 自动安装
3. pip 依赖     ← setup.bat 自动安装
4. Hermes Desktop ← 手动下载安装（或 setup.bat STEP 4 提示）
5. 配置         ← setup.bat 自动生成（需先设环境变量）
```

---

## 二、常见踩坑速查

| 症状 | 原因 | 解决 |
|------|------|------|
| winget 命令不存在 | Windows Server 无应用商店 | setup.bat 自动回退到手动下载 |
| Python 安装报错 | 缺少 VC 运行时 | 安装 [VC++ Redist](https://aka.ms/vs/17/release/vc_redist.x64.exe) |
| curl 下载超时 | 国内网络 | 已配置清华镜像，再试一次 |
| `python` 命令不识别 | PATH 未刷新 | 重启终端或手动跑 `refreshenv` |
| 安装后飞书不对话 | 见下方飞书排障 | 运行 `hermes-fix.bat` |
| 企业内网无法下载 | 无外网/需代理 | 设置 `HTTP_PROXY` 环境变量后重新运行 |

---

## 三、飞书集成排障（7 检查点）

按顺序逐项检查：

| # | 检查项 | 怎么做 |
|---|--------|--------|
| 1 | 应用类型 | 飞书开放平台 → 确认是「企业自建应用」 |
| 2 | 权限范围 | 确认已开通 `im:message` `im:message:send_as_bot` 等权限 |
| 3 | 事件订阅 URL | 确认 URL 可公网访问，已配置验证 |
| 4 | config.yaml 飞书段 | `app_id` `app_secret` 是否正确 |
| 5 | .env 白名单 | `FEISHU_ALLOWED_USERS=ou_你的ID` |
| 6 | 应用发布 | 飞书开放平台 → 应用已发布（非开发状态） |
| 7 | access_key 延迟 | 新发布后等 1-2 分钟再试 |

一键修复：运行 `hermes-fix.bat`（清理 token 缓存 + 锁文件 + 重启）。

---

## 四、锁文件说明

如果 Hermes 异常退出，以下锁文件可能残留：

```
%APPDATA%\cn.org.hermesagent.desktop\runtime\
├── hermes-home\
│   ├── auth.lock
│   ├── kanban.db.init.lock
│   ├── cron\.tick.lock
│   └── skills\.usage.json.lock
└── gateway-runtime\
    ├── gateway.lock
    ├── gateway.pid
    └── token-locks\*.lock
```

运行 `hermes-fix.bat` 自动清理。

---

## 五、服务器部署特殊说明

Windows Server 环境注意事项：

| 差异 | 影响 | 对策 |
|------|------|------|
| 无 winget | Python/Git 无法自动安装 | setup.bat 自动走手动下载分支 |
| 无 GUI | 不能双击运行 Hermes Desktop | 可通过远程桌面或计划任务启动 |
| 防火墙 | 端口被拦截 | 放行 Hermes 所需端口（默认 8080） |
| Server Core | 无桌面环境 | 不支持 Hermes Desktop GUI，需标准版 |

**建议**：服务器上用 `hermes-setup.bat /silent` 静默安装，搭配远程桌面或 Web 版飞书管理。

---

## 六、装后验证清单

```
□ python --version → Python 3.12.x
□ git --version    → git version 2.x
□ 飞书发送消息 → Hermes 回复
□ 进程不闪退 → tasklist 可见 hermes-*.exe
□ 日志无 ERROR → %APPDATA%\...\logs\
```

---

## 七、一键修复

飞书不对话时运行：

```powershell
powershell -c "iwr -Uri 'https://raw.githubusercontent.com/qq449176836-lang/hermes-quick-start/main/hermes-fix.bat' -OutFile fix.bat; .\fix.bat"
```

修复脚本自动执行：清理锁文件 → 清理飞书缓存 → 杀僵尸进程 → 重启 → 健康检查。
