@echo off
setlocal
cd /d "%~dp0"
if exist "%~dp0Server\crystalserver.exe" (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Launcher\Launcher.ps1"
) else (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Tools\Start-PlayablePackage.ps1"
)
if errorlevel 1 pause
endlocal
