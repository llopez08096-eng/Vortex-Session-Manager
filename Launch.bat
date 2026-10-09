@echo off
setlocal
cd /d "%~dp0"
rem Launch without a visible PowerShell console. Requires Launch.vbs.
wscript.exe "%~dp0Launch.vbs"
if errorlevel 1 (
  echo The app could not start. Check that Launch.vbs is in this folder.
  pause
)
