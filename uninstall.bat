@echo off
color 0C
title muxless uninstaller

net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo.
echo Removing muxless tasks...

:: Remove current task names
schtasks /delete /tn "muxless - Manage GPU (logon)" /f >nul 2>&1
schtasks /delete /tn "muxless - Manage GPU (poll)"  /f >nul 2>&1

:: Remove legacy task names (from older installs)
schtasks /delete /tn "muxless - Disable GPU"        /f >nul 2>&1
schtasks /delete /tn "muxless - Disable GPU Retry"  /f >nul 2>&1
schtasks /delete /tn "muxless - Enable GPU"         /f >nul 2>&1

echo Removing files...
rmdir /s /q "%ProgramData%\muxless" >nul 2>&1

echo.
echo muxless removed successfully.
echo.
pause
