@echo off
setlocal EnableExtensions
set "SCRIPT=%~dp0.runtime-windows\scripts\restore-endfield-theme.ps1"
if not exist "%SCRIPT%" (
  echo [ERROR] Runtime script is missing: "%SCRIPT%"
  echo Please extract the complete release before running this file.
  pause
  exit /b 2
)
where powershell.exe >nul 2>nul
if errorlevel 1 (
  echo [ERROR] Windows PowerShell is not available.
  pause
  exit /b 3
)
echo [Codex Hypergryph Theme] Restoring the official appearance...
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%"
set "CODE=%ERRORLEVEL%"
if not "%CODE%"=="0" (
  echo.
  echo [ERROR] Restore failed with exit code %CODE%.
  echo Run the Windows environment checker in this folder for details.
  pause
)
exit /b %CODE%
