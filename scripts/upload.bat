@echo off
setlocal

set "SCRIPT_PATH=%~dp0upload.ps1"

where powershell.exe >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_PATH%"
    goto :done
)

where pwsh.exe >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    pwsh.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_PATH%"
    goto :done
)

echo ERROR: Could not find PowerShell. Install Windows PowerShell or PowerShell 7 (pwsh).

:done
pause
