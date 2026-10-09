@echo off
setlocal
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File "%~dp0VortexSessionManager.ps1"
echo.
echo Process exited. Press any key to close.
pause >nul
