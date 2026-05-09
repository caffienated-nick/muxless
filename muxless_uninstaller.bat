@echo off
setlocal
color 0C

echo Creating PowerShell uninstaller...

set "PS1=%TEMP%\muxless_uninstall.ps1"

(
echo # muxless uninstaller
echo $ErrorActionPreference = "SilentlyContinue"
echo Write-Host ""
echo Write-Host "Removing muxless tasks..." -ForegroundColor Red
echo.
echo schtasks /delete /tn "muxless - Disable GPU" /f
echo schtasks /delete /tn "muxless - Enable GPU" /f
echo.
echo Write-Host "Cleaning up..."
echo.
echo Remove-Item $MyInvocation.MyCommand.Path -ErrorAction SilentlyContinue
echo.
echo Write-Host ""
echo Write-Host "muxless removed successfully." -ForegroundColor Green
echo pause
) > "%PS1%"

echo Running uninstaller...

powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process PowerShell -ArgumentList '-ExecutionPolicy Bypass -File "%PS1%"' -Verb RunAs"

exit
