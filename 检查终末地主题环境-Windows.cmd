@echo off
setlocal EnableExtensions
set "SCRIPT=%~dp0.runtime-windows\scripts\doctor-endfield-theme.ps1"
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
echo [Codex Hypergryph Theme] Running a read-only Windows environment check...
echo.
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%"
set "CODE=%ERRORLEVEL%"
echo.
if "%CODE%"=="0" (
  echo [OK] All Windows environment checks passed.
) else (
  echo [ERROR] Environment check failed with exit code %CODE%.
)
pause
exit /b %CODE%
