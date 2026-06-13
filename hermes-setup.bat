@echo off
setlocal enabledelayedexpansion
title Hermes CN Desktop - 一键安装

:: ============================================================
:: Hermes CN Desktop 一键安装脚本 v2.0
:: 支持: 桌面 / 服务器 / 无人值守
:: 用法: hermes-setup.bat [/silent]
:: ============================================================

:: --- 静默模式检测 ---
set SILENT=0
if /i "%1"=="/silent" set SILENT=1
if /i "%1"=="silent" set SILENT=1
if "%SILENT_ENV%"=="1" set SILENT=1
if defined SILENT_ENV if "%SILENT_ENV%"=="1" set SILENT=1
if "%HERMES_SILENT%"=="1" set SILENT=1

:: --- 日志 ---
set LOGFILE=%TEMP%\hermes-install.log
echo [%date% %time%] === Hermes 安装开始 === > "%LOGFILE%"
if %SILENT%==1 (
    call :log "静默模式启动"
) else (
    echo [Hermes 一键安装工具 v2.0]
    echo 日志文件: %LOGFILE%
    echo.
)

:: --- 代理检测 ---
if defined HTTP_PROXY (
    call :log "检测到代理: %HTTP_PROXY%"
    set "PROXY_FLAG=--proxy %HTTP_PROXY%"
) else (
    set "PROXY_FLAG="
)

:: ============================================================
:: STEP 1: 安装 Python 3.12
:: ============================================================
call :log "STEP 1/7: 安装 Python 3.12..."

where python >nul 2>&1
if %ERRORLEVEL%==0 (
    python --version 2>&1 | findstr "3.12" >nul
    if !ERRORLEVEL!==0 (
        call :log "  Python 3.12 已安装，跳过"
        goto :step2
    )
    call :log "  Python 已安装但非 3.12，继续安装"
)

:: 尝试 winget
where winget >nul 2>&1
if %ERRORLEVEL%==0 (
    call :log "  通过 winget 安装..."
    winget install Python.Python.3.12 --accept-source-agreements --accept-package-agreements --silent >> "%LOGFILE%" 2>&1
    if !ERRORLEVEL!==0 goto :py_done
    call :log "  winget 失败，尝试镜像下载..."
)

:: 手动下载安装
set "PYTHON_URL=https://registry.npmmirror.com/-/binary/python/3.12.9/python-3.12.9-amd64.exe"
set "PYTHON_INSTALLER=%TEMP%\python-installer.exe"
call :log "  下载 Python 3.12.9..."
curl -fsSL %PROXY_FLAG% --connect-timeout 15 --max-time 300 "%PYTHON_URL%" -o "%PYTHON_INSTALLER%" >> "%LOGFILE%" 2>&1
if %ERRORLEVEL% neq 0 (
    call :log "  镜像下载失败，尝试官方源..."
    set "PYTHON_URL=https://www.python.org/ftp/python/3.12.9/python-3.12.9-amd64.exe"
    curl -fsSL %PROXY_FLAG% --connect-timeout 30 --max-time 600 "%PYTHON_URL%" -o "%PYTHON_INSTALLER%" >> "%LOGFILE%" 2>&1
)
if exist "%PYTHON_INSTALLER%" (
    call :log "  安装 Python..."
    "%PYTHON_INSTALLER%" /quiet InstallAllUsers=1 PrependPath=1 Include_test=0 >> "%LOGFILE%" 2>&1
    del "%PYTHON_INSTALLER%" >nul 2>&1
)

:py_done
:: 刷新 PATH
set "PATH=%LOCALAPPDATA%\Programs\Python\Python312;%LOCALAPPDATA%\Programs\Python\Python312\Scripts;%PATH%"
python --version >nul 2>&1
if %ERRORLEVEL% neq 0 (
    call :log "  [FAIL] Python 安装失败"
    if %SILENT%==0 pause
    exit /b 1
)
call :log "  [OK] Python 就绪"

:: ============================================================
:: STEP 2: 安装 Git
:: ============================================================
:step2
call :log "STEP 2/7: 安装 Git for Windows..."

where git >nul 2>&1
if %ERRORLEVEL%==0 (
    call :log "  Git 已安装，跳过"
    goto :step3
)

where winget >nul 2>&1
if %ERRORLEVEL%==0 (
    call :log "  通过 winget 安装..."
    winget install Git.Git --accept-source-agreements --accept-package-agreements --silent >> "%LOGFILE%" 2>&1
    if !ERRORLEVEL!==0 goto :git_done
)

set "GIT_URL=https://github.com/git-for-windows/git/releases/download/v2.47.1.windows.2/Git-2.47.1.2-64-bit.exe"
set "GIT_INSTALLER=%TEMP%\git-installer.exe"
call :log "  下载 Git..."
curl -fsSL %PROXY_FLAG% --connect-timeout 30 --max-time 600 "%GIT_URL%" -o "%GIT_INSTALLER%" >> "%LOGFILE%" 2>&1
if exist "%GIT_INSTALLER%" (
    call :log "  安装 Git（静默）..."
    "%GIT_INSTALLER%" /VERYSILENT /NORESTART /NOCANCEL /SP- /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS >> "%LOGFILE%" 2>&1
    del "%GIT_INSTALLER%" >nul 2>&1
)

:git_done
set "PATH=C:\Program Files\Git\cmd;%PATH%"
git --version >nul 2>&1
if %ERRORLEVEL% neq 0 (
    call :log "  [WARN] Git 安装可能失败，继续..."
)
call :log "  [OK] Git 就绪"

:: ============================================================
:: STEP 3: pip 配置 + 依赖
:: ============================================================
:step3
call :log "STEP 3/7: 配置 pip + 安装依赖..."

python -m pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple >> "%LOGFILE%" 2>&1
python -m pip install --upgrade pip --quiet >> "%LOGFILE%" 2>&1

call :log "  安装 Python 依赖..."
python -m pip install requests python-dotenv pyyaml --quiet >> "%LOGFILE%" 2>&1
call :log "  [OK] 依赖就绪"

:: ============================================================
:: STEP 4: 下载安装 Hermes CN Desktop
:: ============================================================
call :log "STEP 4/7: 安装 Hermes CN Desktop..."

set "HERMES_DIR=%LOCALAPPDATA%\Programs\hermes-agent-cn-desktop"
if exist "%HERMES_DIR%\Hermes Agent CN Desktop.exe" (
    call :log "  Hermes 已安装，跳过"
    goto :step5
)

:: 尝试从官网下载（占位——需要真实下载链接）
call :log "  [WARN] Hermes Desktop 需手动安装"
call :log "  请从官网下载安装包并安装到: %HERMES_DIR%"
call :log "  或提供下载 URL 后重新运行本脚本。"
if %SILENT%==0 (
    echo.
    echo   [提示] Hermes Desktop 安装包需手动下载安装
    echo   安装目录: %HERMES_DIR%
    echo   安装完成后按任意键继续配置...
    pause >nul
)
goto :step5_skip_verify

:: --- 如果有直链，取消下面的注释 ---
:: set "HERMES_URL=https://example.com/hermes-agent-cn-desktop-setup.exe"
:: set "HERMES_INSTALLER=%TEMP%\hermes-installer.exe"
:: curl -fsSL %PROXY_FLAG% --connect-timeout 30 --max-time 600 "%HERMES_URL%" -o "%HERMES_INSTALLER%"
:: "%HERMES_INSTALLER%" /VERYSILENT /DIR="%HERMES_DIR%"

:step5_skip_verify
:: 刷新 PATH（Hermes 可能不在标准路径）
if exist "%HERMES_DIR%" set "PATH=%HERMES_DIR%;%PATH%"

:: ============================================================
:: STEP 5: 生成 config.yaml
:: ============================================================
call :log "STEP 5/7: 生成 config.yaml..."

:: 查找 Hermes 配置目录
set "CONFIG_DIR="
if exist "%APPDATA%\cn.org.hermesagent.desktop\runtime\hermes-home" (
    set "CONFIG_DIR=%APPDATA%\cn.org.hermesagent.desktop\runtime\hermes-home"
) else if exist "%LOCALAPPDATA%\cn.org.hermesagent.desktop\runtime\hermes-home" (
    set "CONFIG_DIR=%LOCALAPPDATA%\cn.org.hermesagent.desktop\runtime\hermes-home"
)

if "%CONFIG_DIR%"=="" (
    call :log "  [WARN] 未找到 Hermes 配置目录，请先启动一次 Hermes Desktop"
    goto :step6
)

set "CONFIG_FILE=%CONFIG_DIR%\config.yaml"
if exist "%CONFIG_FILE%" (
    call :log "  config.yaml 已存在，跳过"
    goto :step6
)

:: 从环境变量读取配置
set "API_KEY=%HERMES_API_KEY%"
set "MODEL=%HERMES_MODEL%"
if "%MODEL%"=="" set "MODEL=deepseek-v4-pro"
set "BASE_URL=%HERMES_BASE_URL%"
if "%BASE_URL%"=="" set "BASE_URL=https://api.deepseek.com"
set "PROVIDER=%HERMES_PROVIDER%"
if "%PROVIDER%"=="" set "PROVIDER=deepseek"

:: 生成 config.yaml
(
echo # Hermes Agent 配置文件（自动生成）
echo model:
echo   default: "%MODEL%"
echo   provider: "%PROVIDER%"
if not "%API_KEY%"=="" (
    echo   api_key: "%API_KEY%"
    echo   base_url: "%BASE_URL%"
)
echo.
echo platforms:
echo   feishu:
echo     enabled: true
echo     app_id: "%FEISHU_APP_ID%"
echo     app_secret: "%FEISHU_APP_SECRET%"
echo.
echo delegation:
echo   max_concurrent_children: 3
echo   max_spawn_depth: 1
echo.
echo terminal:
echo   cwd: "%USERPROFILE%"
echo   shell: bash
) > "%CONFIG_FILE%"

call :log "  [OK] config.yaml 已生成: %CONFIG_FILE%"

:: ============================================================
:: STEP 6: 生成飞书 .env
:: ============================================================
:step6
call :log "STEP 6/7: 配置飞书集成..."

if "%CONFIG_DIR%"=="" goto :step7
set "ENV_FILE=%CONFIG_DIR%\.env"

if defined FEISHU_ALLOWED_USERS (
    if not exist "%ENV_FILE%" (
        (
        echo # 飞书白名单（自动生成）
        echo FEISHU_ALLOWED_USERS=%FEISHU_ALLOWED_USERS%
        ) > "%ENV_FILE%"
        call :log "  [OK] .env 已生成: %ENV_FILE%"
    ) else (
        call :log "  .env 已存在，跳过"
    )
) else (
    call :log "  [INFO] 未设置 FEISHU_ALLOWED_USERS，飞书集成需手动配置"
    call :log "  在 %ENV_FILE% 中添加: FEISHU_ALLOWED_USERS=ou_你的用户ID"
)

:: ============================================================
:: STEP 7: 安装后验证
:: ============================================================
:step7
call :log "STEP 7/7: 安装后验证..."

set OK=1

:: 验证 Python
python --version >nul 2>&1 || (call :log "  [FAIL] Python 不可用" & set OK=0)
if %OK%==1 call :log "  [OK] Python"

:: 验证 Git
git --version >nul 2>&1 || (call :log "  [WARN] Git 不可用（非致命）")
if %OK%==1 git --version >nul 2>&1 && call :log "  [OK] Git"

:: 验证 pip 依赖
python -c "import requests, dotenv, yaml" >nul 2>&1 || (call :log "  [WARN] Python 依赖缺失" & set OK=0)
if %OK%==1 call :log "  [OK] pip 依赖"

:: 验证配置
if exist "%CONFIG_FILE%" (call :log "  [OK] config.yaml") else (call :log "  [INFO] config.yaml 待生成")

:: ============================================================
:: 完成
:: ============================================================
call :log "=== 安装完成 ==="
echo.
if %OK%==1 (
    echo   [安装成功] Hermes CN Desktop 环境已就绪
) else (
    echo   [部分完成] 请检查上方 [FAIL] 项，查看日志: %LOGFILE%
)
echo   配置文件: %CONFIG_FILE%
if "%HERMES_DIR%" neq "" echo   Hermes 目录: %HERMES_DIR%

if %SILENT%==0 (
    echo.
    echo   按任意键退出...
    pause >nul
)

exit /b %OK%

:: ============================================================
:: 工具函数
:: ============================================================
:log
set MSG=[%date% %time%] %~1
echo %MSG% >> "%LOGFILE%"
if %SILENT%==0 echo %~1
exit /b
