@echo off
chcp 65001 >nul
echo ============================================
echo   Hermes CN Desktop 一键修复
echo ============================================
echo.

echo [1/5] 清理锁文件...
del /f "%APPDATA%\cn.org.hermesagent.desktop\runtime\hermes-home\auth.lock" 2>nul
del /f "%APPDATA%\cn.org.hermesagent.desktop\runtime\hermes-home\gateway-runtime\gateway.lock" 2>nul
del /f "%APPDATA%\cn.org.hermesagent.desktop\runtime\hermes-home\kanban.db.init.lock" 2>nul
del /f "%APPDATA%\cn.org.hermesagent.desktop\runtime\hermes-home\cron\.tick.lock" 2>nul
echo    ✓ 锁文件已清理

echo [2/5] 清理飞书 token 缓存（解决 Unauthorized）...
del /f "%APPDATA%\cn.org.hermesagent.desktop\runtime\hermes-home\gateway-runtime\token-locks\*.lock" 2>nul
echo    ✓ 飞书 token 缓存已清理

echo [3/5] 杀掉残留进程...
taskkill /f /im hermes-agent-cn-desktop.exe 2>nul
taskkill /f /im hermes-agent-cn-runtime-w.exe 2>nul
taskkill /f /im python.exe 2>nul
echo    ✓ 残留进程已终止

echo [4/5] 等待 3 秒...
timeout /t 3 /nobreak >nul

echo [5/5] 重新启动 Hermes...
start "" "%LOCALAPPDATA%\Programs\hermes-agent-cn-desktop\hermes-agent-cn-desktop.exe"
echo    ✓ Hermes 已启动

echo.
echo ============================================
echo   修复完成！
echo.
echo   ⚠ 飞书对话测试：
echo      → 等 1-2 分钟（access_key 同步需要时间）
echo      → 然后在飞书发「ping」
echo      → 回复「pong」说明通道正常
echo.
echo   如果不回消息，打开安装指南看「飞书集成排障」
echo ============================================
pause
