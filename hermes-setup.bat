@echo off
chcp 65001 >nul
title Hermes CN Desktop 新机全自动安装

:: ============================================================
:: Hermes CN Desktop — 新机一键全自动安装脚本
:: 自动检测 → 自动下载 → 自动安装 Python / Git / Hermes
:: ============================================================

echo.
echo   ╔══════════════════════════════════════════════════╗
echo   ║   Hermes CN Desktop · 新机全自动安装向导        ║
echo   ╚══════════════════════════════════════════════════╝
echo.

set "FAIL=0"
set "NEED_REBOOT=0"

:: ============================================================
:: STEP 1 — Python 3.12
:: ============================================================
call :section "Python 3.12"

where python >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=2" %%v in ('python --version 2^>^&1') do set pyver=%%v
    echo   ✓ 已安装 Python %pyver%
    python -c "import sys; sys.exit(0 if sys.version_info >= (3,10) else 1)" 2>nul
    if %errorlevel% neq 0 (
        echo   ⚠ 版本低于 3.10，建议升级
        goto :install_python
    )
    goto :python_done
)

:install_python
echo   📥 开始安装 Python 3.12...
echo.

:: 策略 A：winget（Windows 10/11 自带）
where winget >nul 2>&1
if %errorlevel% equ 0 (
    echo   尝试 winget 安装...
    winget install Python.Python.3.12 --accept-source-agreements --accept-package-agreements -h
    if %errorlevel% equ 0 (
        echo   ✓ Python 3.12 安装完成
        set "NEED_REBOOT=1"
        goto :python_done
    )
    echo   winget 失败，改用下载安装...
)

:: 策略 B：国内镜像下载（清华源加速）
echo   从国内镜像下载 Python 安装包...
set "PY_URL=https://registry.npmmirror.com/-/binary/python/3.12.9/python-3.12.9-amd64.exe"
set "PY_INSTALLER=%TEMP%\python-3.12.9-amd64.exe"

powershell -c "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; iwr -Uri '%PY_URL%' -OutFile '%PY_INSTALLER%'" 2>nul
if not exist "%PY_INSTALLER%" (
    :: 备用：官方源
    echo   镜像失败，尝试官方源...
    set "PY_URL=https://www.python.org/ftp/python/3.12.9/python-3.12.9-amd64.exe"
    powershell -c "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; iwr -Uri '%PY_URL%' -OutFile '%PY_INSTALLER%'" 2>nul
)

if not exist "%PY_INSTALLER%" (
    echo   ❌ Python 下载失败，请手动从 https://www.python.org/downloads/ 安装
    echo   （安装时务必勾选 Add Python to PATH）
    set "FAIL=1"
    goto :python_done
)

echo   安装中（静默，约 1 分钟）...
"%PY_INSTALLER%" /quiet InstallAllUsers=1 PrependPath=1 Include_test=0
if %errorlevel% neq 0 (
    "%PY_INSTALLER%" /quiet PrependPath=1
)
del /f "%PY_INSTALLER%" 2>nul
echo   ✓ Python 3.12 安装完成
set "NEED_REBOOT=1"

:python_done
echo.

:: ============================================================
:: STEP 2 — Git for Windows
:: ============================================================
call :section "Git for Windows"

where git >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=3" %%v in ('git --version 2^>^&1') do echo   ✓ 已安装 Git %%v
    goto :git_done
)

echo   📥 开始安装 Git...

where winget >nul 2>&1
if %errorlevel% equ 0 (
    echo   尝试 winget 安装...
    winget install Git.Git --accept-source-agreements --accept-package-agreements -h
    if %errorlevel% equ 0 (
        echo   ✓ Git 安装完成
        set "NEED_REBOOT=1"
        goto :git_done
    )
    echo   winget 失败，改用下载安装...
)

set "GIT_URL=https://github.com/git-for-windows/git/releases/download/v2.47.1.windows.2/Git-2.47.1-64-bit.exe"
set "GIT_INSTALLER=%TEMP%\Git-2.47.1-64-bit.exe"

powershell -c "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; iwr -Uri '%GIT_URL%' -OutFile '%GIT_INSTALLER%'" 2>nul

if not exist "%GIT_INSTALLER%" (
    echo   ❌ Git 下载失败，请手动从 https://git-scm.com/download/win 安装
    set "FAIL=1"
    goto :git_done
)

echo   安装中（静默）...
"%GIT_INSTALLER%" /VERYSILENT /NORESTART
del /f "%GIT_INSTALLER%" 2>nul
echo   ✓ Git 安装完成
set "NEED_REBOOT=1"

:git_done
echo.

:: ============================================================
:: STEP 3 — pip 升级 + 常用包
:: ============================================================
call :section "pip + Python 依赖"

pip --version >nul 2>&1
if %errorlevel% neq 0 (
    python -m ensurepip --upgrade 2>nul
)

echo   升级 pip + 安装常用包（国内镜像加速）...
pip install --upgrade pip -i https://pypi.tuna.tsinghua.edu.cn/simple --quiet 2>nul

:: Hermes 桌面版自带了大部分依赖，这里只补可能缺的
pip install requests python-dotenv -i https://pypi.tuna.tsinghua.edu.cn/simple --quiet 2>nul

echo   ✓ pip 就绪
echo.

:: ============================================================
:: STEP 4 — Hermes CN Desktop
:: ============================================================
call :section "Hermes CN Desktop"

if exist "%LOCALAPPDATA%\Programs\hermes-agent-cn-desktop\hermes-agent-cn-desktop.exe" (
    echo   ✓ Hermes CN Desktop 已安装
) else (
    echo   ⚠ Hermes CN Desktop 未安装
    echo   👉 请从官方渠道获取安装包，双击安装即可
    echo   👉 默认安装路径：%LOCALAPPDATA%\Programs\hermes-agent-cn-desktop\
    set "FAIL=1"
)
echo.

:: ============================================================
:: STEP 5 — 生成 config.yaml 模板
:: ============================================================
call :section "生成配置文件模板"

set "CONFIG_DIR=%APPDATA%\cn.org.hermesagent.desktop\runtime\hermes-home"
set "CONFIG_FILE=%CONFIG_DIR%\config.yaml"

if exist "%CONFIG_FILE%" (
    echo   ✓ config.yaml 已存在，跳过（如需覆盖请手动删除后重跑）
    goto :config_done
)

if not exist "%CONFIG_DIR%" mkdir "%CONFIG_DIR%"

(
echo # === Hermes CN Desktop 配置模板 ===
echo # 搜「替换为你的」填 4 个占位符，其他保持默认
echo.
echo model:
echo   provider: deepseek
echo   default: deepseek-v4-pro
echo   base_url: https://api.deepseek.com
echo   api_mode: chat_completions
echo   api_key: 替换为你的DeepSeek-API-Key
echo.
echo providers:
echo   deepseek:
echo     name: DeepSeek
echo     base_url: https://api.deepseek.com
echo     api_mode: chat_completions
echo     transport: openai_chat
echo     model: deepseek-v4-pro
echo     models:
echo       deepseek-v4-flash:
echo         supports_tools: true
echo       deepseek-v4-pro:
echo         supports_tools: true
echo         supports_reasoning: true
echo     api_key: 替换为你的DeepSeek-API-Key
echo.
echo terminal:
echo   backend: local
echo.
echo delegation:
echo   max_concurrent_children: 3
echo.
echo feishu:
echo   enabled: true
echo   app_id: 替换为你的飞书AppID
echo   app_secret: 替换为你的飞书AppSecret
) > "%CONFIG_FILE%"

echo   ✓ config.yaml 已生成
echo   📝 请用记事本打开，搜「替换为你的」填 4 个值
echo.

:config_done

:: ============================================================
:: STEP 6 — 下载辅助脚本
:: ============================================================
call :section "下载辅助脚本"

set "BASE=https://raw.githubusercontent.com/qq449176836-lang/hermes-quick-start/main"

if not exist "hermes-fix.bat" (
    powershell -c "iwr -Uri '%BASE%/hermes-fix.bat' -OutFile 'hermes-fix.bat'" 2>nul
    if exist "hermes-fix.bat" (echo   ✓ hermes-fix.bat 已下载) else (echo   ⚠ 下载失败)
) else (echo   ✓ hermes-fix.bat 已存在)

if not exist "hermes-install-guide.md" (
    powershell -c "iwr -Uri '%BASE%/hermes-install-guide.md' -OutFile 'hermes-install-guide.md'" 2>nul
    if exist "hermes-install-guide.md" (echo   ✓ hermes-install-guide.md 已下载) else (echo   ⚠ 下载失败)
) else (echo   ✓ hermes-install-guide.md 已存在)

echo.

:: ============================================================
:: 总结
:: ============================================================
echo   ╔══════════════════════════════════════════════════╗
echo   ║                  安装完成！                      ║
echo   ╚══════════════════════════════════════════════════╝
echo.

if "%NEED_REBOOT%"=="1" (
    echo   🔄 安装了系统级软件（Python / Git），建议重启终端
    echo   或重新打开命令提示符后再继续。
    echo.
)

if "%FAIL%"=="1" (
    echo   ⚠ 部分组件未自动安装成功，请按上方提示手动处理。
) else (
    echo   ✅ 所有组件就绪！
)

echo.
echo   📋 接下来你只需要做：
echo   1. 安装 Hermes CN Desktop（如未装）
echo   2. 用记事本打开：
echo      %CONFIG_FILE%
echo   3. 搜「替换为你的」，填 4 个值：
echo      · DeepSeek API Key（2 处）
echo      · 飞书 App ID
echo      · 飞书 App Secret
echo   4. 启动 Hermes Desktop，飞书测试
echo.
echo   🛠 出故障时，右键管理员运行 hermes-fix.bat
echo.
pause
exit /b 0

:: ============================================================
:: 显示小节标题
:: ============================================================
:section
echo   ───────────────────────────────────────────────
echo   %~1
echo   ───────────────────────────────────────────────
exit /b 0
