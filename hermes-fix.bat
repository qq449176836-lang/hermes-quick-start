@echo off
setlocal enabledelayedexpansion
title Hermes - 一键修复

:: ============================================================
:: Hermes 一键修复脚本 v2.0
:: 适用: 飞书不对话 / 锁文件残留 / 进程崩溃
:: 用法: hermes-fix.bat [/silent]
:: ============================================================

set SILENT=0
if /i "%1"=="/silent" set SILENT=1

set LOGFILE=%TEMP%\hermes-fix.log
echo [%date% %time%] === 修复开始 === > "%LOGFILE%"

:: 定位目录
set "HERMES_HOME=%APPDATA%\cn.org.hermesagent.desktop\runtime\hermes-home"
set "GATEWAY_RUNTIME=%APPDATA%\cn.org.hermesagent.desktop\runtime\gateway-runtime"
if not exist "%HERMES_HOME%" set "HERMES_HOME=%LOCALAPPDATA%\cn.org.hermesagent.desktop\runtime\hermes-home"
if not exist "%GATEWAY_RUNTIME%" set "GATEWAY_RUNTIME=%LOCALAPPDATA%\cn.org.hermesagent.desktop\runtime\gateway-runtime"

if not exist "%HERMES_HOME%" (
    echo [FAIL] 找不到 Hermes 目录，请确认已安装 Hermes CN Desktop
    if %SILENT%==0 pause
    exit /b 1
)

if %SILENT%==0 echo [Hermes 一键修复]
echo 日志: %LOGFILE%

:: ============================================================
:: [1/6] 清理锁文件
:: ============================================================
call :log "[1/6] 清理锁文件..."

for %%F in (
    "%HERMES_HOME%\auth.lock"
    "%HERMES_HOME%\kanban.db.init.lock"
    "%HERMES_HOME%\cron\.tick.lock"
    "%HERMES_HOME%\skills\.usage.json.lock"
    "%GATEWAY_RUNTIME%\gateway.lock"
    "%GATEWAY_RUNTIME%\gateway.pid"
) do (
    if exist "%%F" (
        del /f /q "%%F" >nul 2>&1
        call :log "  删除: %%F"
    )
)

:: 清理 token-locks 目录
if exist "%GATEWAY_RUNTIME%\token-locks" (
    del /f /q "%GATEWAY_RUNTIME%\token-locks\*.lock" >nul 2>&1
    call :log "  清理 token-locks"
)

:: ============================================================
:: [2/6] 清理飞书 token 缓存
:: ============================================================
call :log "[2/6] 清理飞书 token 缓存..."

for %%F in (
    "%HERMES_HOME%\feishu_token.json"
    "%HERMES_HOME%\feishu_token_cache.json"
) do (
    if exist "%%F" (
        del /f /q "%%F" >nul 2>&1
        call :log "  删除: %%F"
    )
)

:: ============================================================
:: [3/6] 杀掉僵尸进程
:: ============================================================
call :log "[3/6] 终止残留进程..."

for %%P in (hermes-agent-cn-runtime-win32-x64.exe hermes-agent-cn-desktop.exe) do (
    tasklist /fi "imagename eq %%P" 2>nul | find /i "%%P" >nul
    if !ERRORLEVEL!==0 (
        taskkill /f /im "%%P" >nul 2>&1
        call :log "  终止: %%P"
    )
)

:: python.exe 仅杀 Hermes 目录下的
for /f "tokens=2" %%a in ('tasklist /fi "imagename eq python.exe" /fo csv ^| findstr /i "python"') do (
    wmic process where processid=%%a get executablepath 2>nul | findstr /i "hermes" >nul
    if !ERRORLEVEL!==0 (
        taskkill /f /pid %%a >nul 2>&1
        call :log "  终止: python.exe (PID %%a)"
    )
)

:: ============================================================
:: [4/6] 等待进程清空
:: ============================================================
call :log "[4/6] 等待进程退出..."
timeout /t 3 /nobreak >nul

:: ============================================================
:: [5/6] 重启 Hermes Desktop
:: ============================================================
call :log "[5/6] 启动 Hermes Desktop..."

set "HERMES_EXE=%LOCALAPPDATA%\Programs\hermes-agent-cn-desktop\Hermes Agent CN Desktop.exe"
if not exist "%HERMES_EXE%" (
    call :log "  [FAIL] 找不到 Hermes Desktop: %HERMES_EXE%"
    goto :verify
)

start "" "%HERMES_EXE%"
call :log "  已启动: %HERMES_EXE%"

:: ============================================================
:: [6/6] 健康检查
:: ============================================================
:verify
call :log "[6/6] 健康检查..."

timeout /t 5 /nobreak >nul

:: 检查 Hermes 进程
tasklist /fi "imagename eq hermes-agent-cn-desktop.exe" 2>nul | find /i "hermes" >nul
if %ERRORLEVEL%==0 (
    call :log "  [OK] Hermes Desktop 运行中"
) else (
    call :log "  [WARN] Hermes Desktop 未检测到，可能正在启动..."
)

:: 检查 Gateway
if exist "%GATEWAY_RUNTIME%\gateway_state.json" (
    call :log "  [OK] Gateway 状态文件存在"
) else (
    call :log "  [INFO] Gateway 状态文件尚未生成（正常，首次启动需 10-30 秒）"
)

:: ============================================================
:: 完成
:: ============================================================
call :log "=== 修复完成 ==="
echo.
echo   修复完成。如果飞书仍不对话，请检查:
echo   1. 飞书应用是否已发布
echo   2. config.yaml 中 app_id/app_secret 是否正确
echo   3. .env 中 FEISHU_ALLOWED_USERS 是否配置

if %SILENT%==0 (
    echo.
    echo   按任意键退出...
    pause >nul
)
exit /b 0

:log
set MSG=[%date% %time%] %~1
echo %MSG% >> "%LOGFILE%"
if %SILENT%==0 echo %~1
exit /b
