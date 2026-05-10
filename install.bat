@echo off
setlocal
color 0A
title muxless installer

net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

powershell -NoProfile -ExecutionPolicy Bypass -Command "$f='%~f0';$l=[IO.File]::ReadAllLines($f);$s=[Array]::IndexOf($l,'<#PS1');$e=[Array]::IndexOf($l,'PS1#>');if($s-ge0-and$e-gt$s){[scriptblock]::Create(($l[($s+1)..($e-1)]-join\"`n\")).Invoke()}else{Write-Host 'ERROR: installer block not found.' -ForegroundColor Red;Read-Host}"
exit /b

<#PS1
cls

Write-Host ""
Write-Host "                   ++++++++++++++++++++++++++++++++  ++++++++++++++++++++++++++++++++" -ForegroundColor Green
Write-Host "                  +++++++++++++++++++++++++++++++++  +++++++++++++++++++++++++++++++++++" -ForegroundColor Green
Write-Host "                  +++++++++++++++++++++++++++++++++  +++ +++++++++++++++++++++++++++++++" -ForegroundColor Green
Write-Host "                  +++++++++++++++++++++++++++++++++  +  ++++++++++++++++++++++++++++++++" -ForegroundColor Green
Write-Host "                  +++++++++++++++++++++++++++++++++     ++++++++++++++++++++++++++++++++" -ForegroundColor Green
Write-Host "                  +++++++++++++++++++++++++++++++++   + ++++++++++++++++++++++++++++++++" -ForegroundColor Green
Write-Host "                  +++++++++++++++++++++++++++++++++  ++ ++++++++++++++++++++++++++++++++" -ForegroundColor Green
Write-Host "                  +++++++++++++++++++++++++++++++++ +++ ++++++++++++++++++++++++++++++++" -ForegroundColor Green
Write-Host "                  ++++++++++++++++++++++++++++++++ +++++++++++++++++++++++++++++++++++++" -ForegroundColor Green
Write-Host "                  +++++++++++++++++++++++++++++++ ++++ +++++++++++++++++++++++++++++++++" -ForegroundColor Green
Write-Host "                  ++++++++++++++++++++++++++++++ ++-++ +++++++++++++++++++++++++++++++++" -ForegroundColor Green
Write-Host "                  +++++++++++++++++++++++++++++ ++--++ +++++++++++++++++++++++++++++++++" -ForegroundColor Green
Write-Host "                  ++++++++++++++++++++++++++++ ++---++ +++++++++++++++++++++++++++++++++" -ForegroundColor Green
Write-Host "                  +++++++++++++++++++++++++++ ++----++ +++++++++++++++++++++++++++++++++" -ForegroundColor Green
Write-Host "                  ++++++++++++++++++++++++++ +++---+++++++++++++++++++++++++++++++++++++" -ForegroundColor Green
Write-Host "                  +++++++++++++++++++++++++ +++----+++ +++++++++++++++++++++++++++++++++" -ForegroundColor Green
Write-Host "                  ++++++++++++++++++++++++++++-----+++++++++++++  ++++++++++++++++++++++" -ForegroundColor Green
Write-Host "                  +++++++++++++++++++++++ +++----------------+++ +++++++++++++++++++++++" -ForegroundColor Green
Write-Host "                                         +++----------------+++" -ForegroundColor Green
Write-Host "                  +++++++++++++++++++++ +++----------------+++ +++++++++++++++++++++++++" -ForegroundColor Green
Write-Host "                  +++++++++++++++++++++ +++++++++++++-----++++++++++++++++++++++++++++++" -ForegroundColor Green
Write-Host "                  +++++++++++++++++++++++++++++++ +++----+++ +++++++++++++++++++++++++++" -ForegroundColor Green
Write-Host "                  +++++++++++++++++++++++++++++++++++---+++ ++++++++++++++++++++++++++++" -ForegroundColor Green
Write-Host "                  +++++++++++++++++++++++++++++++ ++---+++ +++++++++++++++++++++++++++++" -ForegroundColor Green
Write-Host "                  +++++++++++++++++++++++++++++++ ++--+++ ++++++++++++++++++++++++++++++" -ForegroundColor Green
Write-Host "                  +++++++++++++++++++++++++++++++ ++-+++ +++++++++++++++++++++++++++++++" -ForegroundColor Green
Write-Host "                  +++++++++++++++++++++++++++++++ +++++ ++++++++++++++++++++++++++++++++" -ForegroundColor Green
Write-Host "                  ++++++++++++++++++++++++++++++ +++++ +++++++++++++++++++++++++++++++++" -ForegroundColor Green
Write-Host "                  ++++++++++++++++++++++++++++++ ++++ ++++++++++++++++++++++++++++++++++" -ForegroundColor Green
Write-Host "                  ++++++++++++++++++++++++++++++ +++ +++++++++++++++++++++++++++++++++++" -ForegroundColor Green
Write-Host "                  +++++++++++++++++++++++++++++++++  +++++++++++++++++++++++++++++++++++" -ForegroundColor Green
Write-Host "                  +++++++++++++++++++++++++++++ ++   +++++++++++++++++++++++++++++++++++" -ForegroundColor Green
Write-Host "                  +++++++++++++++++++++++++++++ + +  +++++++++++++++++++++++++++++++++++" -ForegroundColor Green
Write-Host "                  +++++++++++++++++++++++++++++  ++  +++++++++++++++++++++++++++++++++++" -ForegroundColor Green
Write-Host "                  ++++++++++++++++++++++++++++  +++  +++++++++++++++++++++++++++++++++++" -ForegroundColor Green
Write-Host "                  ++++++++++++++++++++++++++++ ++++  +++++++++++++++++++++++++++++++++++" -ForegroundColor Green
Write-Host "                   ++++++++++++++++++++++++++++++++ +++++++++++++++++++++++++++++++++++" -ForegroundColor Green
Write-Host ""
Write-Host "                                        muxless installer" -ForegroundColor Green
Write-Host ""

# ── GPU detection ───────────────────────────────────────────────────────────────
Write-Host "Detecting NVIDIA GPU..." -ForegroundColor Green

$gpu = Get-CimInstance Win32_VideoController |
       Where-Object { $_.PNPDeviceID -like 'PCI\VEN_10DE*' } |
       Select-Object -First 1

if (-not $gpu) {
    Write-Host "ERROR: No NVIDIA GPU detected." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

$GPU_ID = $gpu.PNPDeviceID
Write-Host "Found: $GPU_ID" -ForegroundColor White
Write-Host ""

# ── Write managed script ─────────────────────────────────────────────────────
$dir = "$env:ProgramData\muxless"
New-Item -ItemType Directory -Force -Path $dir | Out-Null

# Single script handles both disable (battery + idle) and enable (AC power).
# Runs on logon and every 2 minutes — no fragile event trigger needed.
$manageScript = @"
Add-Type -AssemblyName System.Windows.Forms
`$gpu = '$GPU_ID'
`$ac  = ([System.Windows.Forms.SystemInformation]::PowerStatus.PowerLineStatus -eq 'Online')

if (`$ac) {
    # On AC power: make sure GPU is enabled
    Enable-PnpDevice -InstanceId `$gpu -Confirm:`$false -ErrorAction SilentlyContinue
} else {
    # On battery: disable GPU only when idle (utilization < 5 %)
    `$u = (nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>`$null)
    if (`$u -match '^\d+$' -and [int]`$u -lt 5) {
        Disable-PnpDevice -InstanceId `$gpu -Confirm:`$false -ErrorAction SilentlyContinue
    }
}
"@

Set-Content -Path "$dir\manage_gpu.ps1" -Value $manageScript -Encoding UTF8

# ── Scheduled tasks ──────────────────────────────────────────────────────────
Write-Host "Creating scheduled tasks..." -ForegroundColor Green

# Clean up any tasks from older versions
foreach ($name in @(
    "muxless - Disable GPU",
    "muxless - Disable GPU Retry",
    "muxless - Enable GPU",
    "muxless - Manage GPU (logon)",
    "muxless - Manage GPU (poll)"
)) {
    schtasks /delete /tn $name /f 2>$null | Out-Null
}

$psFile = "$dir\manage_gpu.ps1"
$tr = "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File $psFile"

# Task 1: run at every logon (catches the most common case)
schtasks /create /tn "muxless - Manage GPU (logon)" `
    /sc onlogon /rl highest /ru SYSTEM /tr $tr /f | Out-Null

# Task 2: poll every 2 minutes (handles plug/unplug while logged in)
schtasks /create /tn "muxless - Manage GPU (poll)" `
    /sc minute /mo 2 /rl highest /ru SYSTEM /tr $tr /f | Out-Null

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "muxless installed successfully." -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "WARNING: One or more tasks may not have been created." -ForegroundColor Yellow
    Write-Host "Try running the installer again as Administrator." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Tasks created:" -ForegroundColor White
Write-Host "  muxless - Manage GPU (logon)   runs at every logon"
Write-Host "  muxless - Manage GPU (poll)    runs every 2 minutes"
Write-Host ""
Write-Host "Behavior:" -ForegroundColor White
Write-Host "  Battery + GPU idle (<5%)  ->  GPU disabled"
Write-Host "  AC power                  ->  GPU enabled"
Write-Host ""
Write-Host "IMPORTANT:" -ForegroundColor Yellow
Write-Host "  - Ensure NVIDIA drivers are installed"
Write-Host "  - Rerun installer if drivers change"
Write-Host ""
Read-Host "Press Enter to exit"
PS1#>
