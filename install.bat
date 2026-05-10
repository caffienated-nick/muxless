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
Write-Host "                  ++++++++++++++++++++++++++++++++  ++++++++++++++++++++++++++++++++                   " -ForegroundColor Green
Write-Host "                  +++++++++++++++++++++++++++++++++  +++++++++++++++++++++++++++++++++                  " -ForegroundColor Green
Write-Host "                  +++++++++++++++++++++++++++++++++  +++ +++++++++++++++++++++++++++++                  " -ForegroundColor Green
Write-Host "                  +++++++++++++++++++++++++++++++++  +  ++++++++++++++++++++++++++++++                  " -ForegroundColor Green
Write-Host "                  +++++++++++++++++++++++++++++++++     ++++++++++++++++++++++++++++++                  " -ForegroundColor Green
Write-Host "                  +++++++++++++++++++++++++++++++++   + ++++++++++++++++++++++++++++++                  " -ForegroundColor Green
Write-Host "                  +++++++++++++++++++++++++++++++++  ++ ++++++++++++++++++++++++++++++                  " -ForegroundColor Green
Write-Host "                  +++++++++++++++++++++++++++++++++ +++ ++++++++++++++++++++++++++++++                  " -ForegroundColor Green
Write-Host "                  ++++++++++++++++++++++++++++++++ +++++++++++++++++++++++++++++++++++                  " -ForegroundColor Green
Write-Host "                  +++++++++++++++++++++++++++++++ ++++ +++++++++++++++++++++++++++++++                  " -ForegroundColor Green
Write-Host "                  ++++++++++++++++++++++++++++++ ++-++ +++++++++++++++++++++++++++++++                  " -ForegroundColor Green
Write-Host "                  +++++++++++++++++++++++++++++ ++--++ +++++++++++++++++++++++++++++++                  " -ForegroundColor Green
Write-Host "                  ++++++++++++++++++++++++++++ ++---++ +++++++++++++++++++++++++++++++                  " -ForegroundColor Green
Write-Host "                  +++++++++++++++++++++++++++ ++----++ +++++++++++++++++++++++++++++++                  " -ForegroundColor Green
Write-Host "                  ++++++++++++++++++++++++++ +++---+++++++++++++++++++++++++++++++++++                  " -ForegroundColor Green
Write-Host "                  +++++++++++++++++++++++++ +++----+++ +++++++++++++++++++++++++++++++                  " -ForegroundColor Green
Write-Host "                  ++++++++++++++++++++++++++++-----+++++++++++++  ++++++++++++++++++++                  " -ForegroundColor Green
Write-Host "                  +++++++++++++++++++++++ +++----------------+++ +++++++++++++++++++++                  " -ForegroundColor Green
Write-Host "                                         +++----------------+++                                         " -ForegroundColor Green
Write-Host "                  +++++++++++++++++++++ +++----------------+++ +++++++++++++++++++++++                  " -ForegroundColor Green
Write-Host "                  +++++++++++++++++++++ +++++++++++++-----++++++++++++++++++++++++++++                  " -ForegroundColor Green
Write-Host "                  +++++++++++++++++++++++++++++++ +++----+++ +++++++++++++++++++++++++                  " -ForegroundColor Green
Write-Host "                  +++++++++++++++++++++++++++++++++++---+++ ++++++++++++++++++++++++++                  " -ForegroundColor Green
Write-Host "                  +++++++++++++++++++++++++++++++ ++---+++ +++++++++++++++++++++++++++                  " -ForegroundColor Green
Write-Host "                  +++++++++++++++++++++++++++++++ ++--+++ ++++++++++++++++++++++++++++                  " -ForegroundColor Green
Write-Host "                  +++++++++++++++++++++++++++++++ ++-+++ +++++++++++++++++++++++++++++                  " -ForegroundColor Green
Write-Host "                  +++++++++++++++++++++++++++++++ +++++ ++++++++++++++++++++++++++++++                  " -ForegroundColor Green
Write-Host "                  ++++++++++++++++++++++++++++++ +++++ +++++++++++++++++++++++++++++++                  " -ForegroundColor Green
Write-Host "                  ++++++++++++++++++++++++++++++ ++++ ++++++++++++++++++++++++++++++++                  " -ForegroundColor Green
Write-Host "                  ++++++++++++++++++++++++++++++ +++ +++++++++++++++++++++++++++++++++                  " -ForegroundColor Green
Write-Host "                  +++++++++++++++++++++++++++++++++  +++++++++++++++++++++++++++++++++                  " -ForegroundColor Green
Write-Host "                  +++++++++++++++++++++++++++++ ++   +++++++++++++++++++++++++++++++++                  " -ForegroundColor Green
Write-Host "                  +++++++++++++++++++++++++++++ + +  +++++++++++++++++++++++++++++++++                  " -ForegroundColor Green
Write-Host "                  +++++++++++++++++++++++++++++  ++  +++++++++++++++++++++++++++++++++                  " -ForegroundColor Green
Write-Host "                  ++++++++++++++++++++++++++++  +++  +++++++++++++++++++++++++++++++++                  " -ForegroundColor Green
Write-Host "                  ++++++++++++++++++++++++++++ ++++  +++++++++++++++++++++++++++++++++                  " -ForegroundColor Green
Write-Host "                   ++++++++++++++++++++++++++++++++  ++++++++++++++++++++++++++++++++                   " -ForegroundColor Green
Write-Host ""
Write-Host "                                         muxless installer" -ForegroundColor Green
Write-Host ""

# ── GPU detection ────────────────────────────────────────────────────────────
Write-Host "Detecting NVIDIA GPU..." -ForegroundColor Green

$gpu = Get-CimInstance Win32_VideoController |
       Where-Object { $_.PNPDeviceID -like 'PCI\VEN_10DE*' } |
       Select-Object -First 1

if (-not $gpu) {
    Write-Host "ERROR: No NVIDIA GPU detected." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

$GPU_ID  = $gpu.PNPDeviceID
$GPU_XML = $GPU_ID -replace '&', '&amp;'   # XML-escape ampersands in the device ID

Write-Host "Found: $GPU_ID" -ForegroundColor White
Write-Host ""

# ── Current user SID ─────────────────────────────────────────────────────────
# Tasks must run as the current user (S4U), NOT SYSTEM.
# Disable-PnpDevice and pnputil both work correctly this way.
$SID = ([System.Security.Principal.WindowsIdentity]::GetCurrent()).User.Value
Write-Host "User SID: $SID" -ForegroundColor DarkGray
Write-Host ""

# ── Task XML definitions ──────────────────────────────────────────────────────
#
# DISABLE task
#   Triggers : (1) EventTrigger on Kernel-Power EventID=105
#              (2) LogonTrigger repeating every 2 minutes indefinitely
#   Principal: current user, S4U, HighestAvailable
#   Settings : DisallowStartIfOnBatteries = false   <-- must run on battery
#   Action   : powershell inline -Command (Disable-PnpDevice when battery + idle)
#
# ENABLE task
#   Trigger  : EventTrigger on Kernel-Power EventID=105
#   Principal: current user, S4U, HighestAvailable
#   Settings : DisallowStartIfOnBatteries = true    <-- OS filters: only fires on AC
#   Action   : cmd.exe /c pnputil /enable-device

$disableXml = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <URI>\muxless - Disable GPU (on battery)</URI>
  </RegistrationInfo>
  <Triggers>
    <EventTrigger>
      <Enabled>true</Enabled>
      <Subscription>&lt;QueryList&gt;&lt;Query Id="0" Path="System"&gt;&lt;Select Path="System"&gt;*[System[Provider[@Name='Microsoft-Windows-Kernel-Power'] and EventID=105]]&lt;/Select&gt;&lt;/Query&gt;&lt;/QueryList&gt;</Subscription>
    </EventTrigger>
    <LogonTrigger>
      <Repetition>
        <Interval>PT2M</Interval>
        <StopAtDurationEnd>false</StopAtDurationEnd>
      </Repetition>
      <Enabled>true</Enabled>
    </LogonTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <UserId>$SID</UserId>
      <LogonType>S4U</LogonType>
      <RunLevel>HighestAvailable</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>false</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <IdleSettings>
      <StopOnIdleEnd>false</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>false</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <DisallowStartOnRemoteAppSession>false</DisallowStartOnRemoteAppSession>
    <UseUnifiedSchedulingEngine>true</UseUnifiedSchedulingEngine>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT0S</ExecutionTimeLimit>
    <Priority>7</Priority>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>powershell.exe</Command>
      <Arguments>-ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -Command &quot;Add-Type -AssemblyName System.Windows.Forms; `$ac=([System.Windows.Forms.SystemInformation]::PowerStatus.PowerLineStatus -eq 'Online'); if(-not `$ac){`$u=(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2&gt;`$null); if(`$u -ne `$null -and [int]`$u -lt 5){Disable-PnpDevice -InstanceId \&quot;$GPU_XML\&quot; -Confirm:`$false}}&quot;</Arguments>
    </Exec>
  </Actions>
</Task>
"@

$enableXml = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <URI>\muxless - Enable GPU (on AC)</URI>
  </RegistrationInfo>
  <Triggers>
    <EventTrigger>
      <Enabled>true</Enabled>
      <Subscription>&lt;QueryList&gt;&lt;Query Id="0" Path="System"&gt;&lt;Select Path="System"&gt;*[System[Provider[@Name='Microsoft-Windows-Kernel-Power'] and EventID=105]]&lt;/Select&gt;&lt;/Query&gt;&lt;/QueryList&gt;</Subscription>
    </EventTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <UserId>$SID</UserId>
      <LogonType>S4U</LogonType>
      <RunLevel>HighestAvailable</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>true</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>false</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <IdleSettings>
      <StopOnIdleEnd>false</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>false</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <DisallowStartOnRemoteAppSession>false</DisallowStartOnRemoteAppSession>
    <UseUnifiedSchedulingEngine>true</UseUnifiedSchedulingEngine>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT72H</ExecutionTimeLimit>
    <Priority>7</Priority>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>cmd.exe</Command>
      <Arguments>/c timeout /t 2 &gt;nul &amp;&amp; pnputil /enable-device &quot;$GPU_XML&quot;</Arguments>
    </Exec>
  </Actions>
</Task>
"@

# ── Write XMLs as UTF-16 LE (required by schtasks /xml) ──────────────────────
$disablePath = "$env:TEMP\muxless_disable.xml"
$enablePath  = "$env:TEMP\muxless_enable.xml"

[IO.File]::WriteAllText($disablePath, $disableXml, [System.Text.Encoding]::Unicode)
[IO.File]::WriteAllText($enablePath,  $enableXml,  [System.Text.Encoding]::Unicode)

# ── Remove any existing muxless tasks (old and new names) ────────────────────
Write-Host "Removing old tasks (if any)..." -ForegroundColor DarkGray
@(
    "muxless - Disable GPU",
    "muxless - Disable GPU Retry",
    "muxless - Enable GPU",
    "muxless - Manage GPU (logon)",
    "muxless - Manage GPU (poll)",
    "muxless - Disable GPU (on battery)",
    "muxless - Enable GPU (on AC)"
) | ForEach-Object { schtasks /delete /tn $_ /f 2>$null | Out-Null }

# ── Import tasks via XML ──────────────────────────────────────────────────────
Write-Host "Installing tasks..." -ForegroundColor Green

$r1 = schtasks /create /tn "muxless - Disable GPU (on battery)" /xml $disablePath /f 2>&1
$r2 = schtasks /create /tn "muxless - Enable GPU (on AC)"       /xml $enablePath  /f 2>&1

Remove-Item $disablePath -ErrorAction SilentlyContinue
Remove-Item $enablePath  -ErrorAction SilentlyContinue

# ── Report ────────────────────────────────────────────────────────────────────
Write-Host ""
if ($LASTEXITCODE -eq 0) {
    Write-Host "muxless installed successfully." -ForegroundColor Green
} else {
    Write-Host "WARNING: A task may not have registered correctly." -ForegroundColor Yellow
    Write-Host $r1 -ForegroundColor DarkGray
    Write-Host $r2 -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "Tasks:" -ForegroundColor White
Write-Host "  muxless - Disable GPU (on battery)"
Write-Host "    -> Runs at logon + every 2 min"
Write-Host "    -> Disables GPU if battery AND utilization < 5%"
Write-Host ""
Write-Host "  muxless - Enable GPU (on AC)"
Write-Host "    -> Fires on power-source change (EventID 105)"
Write-Host "    -> OS blocks it on battery (DisallowStartIfOnBatteries=true)"
Write-Host "    -> Re-enables GPU via pnputil"
Write-Host ""
Write-Host "IMPORTANT:" -ForegroundColor Yellow
Write-Host "  Rerun this installer after updating NVIDIA drivers."
Write-Host ""
Read-Host "Press Enter to exit"
PS1#>
