@echo off
color 0A
title muxless installer

echo.
echo muxless installer
echo.

:: Check admin
net session >nul 2>&1
if %errorlevel% neq 0 (
echo Requesting admin...
powershell -Command "Start-Process cmd -ArgumentList '/c %~s0' -Verb RunAs"
exit
)

echo Running as admin...
echo.

powershell -NoExit -ExecutionPolicy Bypass -Command ^
"
Clear-Host
Write-Host 'muxless installer' -ForegroundColor Green
Write-Host ''

Write-Host 'Detecting NVIDIA GPU...' -ForegroundColor Green

$gpu = Get-CimInstance Win32_VideoController | Where-Object { $_.PNPDeviceID -like 'PCI\VEN_10DE*' } | Select-Object -First 1

if (-not $gpu) {
Write-Host 'ERROR: No NVIDIA GPU found' -ForegroundColor Red
pause
exit
}

$GPU_ID = $gpu.PNPDeviceID

Write-Host 'Found GPU:'
Write-Host $GPU_ID
Write-Host ''

$enableXML = @'
<Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task\"> <Triggers> <EventTrigger> <Enabled>true</Enabled> <Subscription> <QueryList>
<Query Id="0" Path="System">
<Select Path="System">
*[System[Provider[@Name='Microsoft-Windows-Kernel-Power'] and EventID=105]] </Select> </Query> </QueryList> </Subscription> </EventTrigger> </Triggers> <Principals>
<Principal id="Author"> <RunLevel>HighestAvailable</RunLevel> </Principal> </Principals> <Settings> <Enabled>true</Enabled> </Settings>
<Actions Context="Author"> <Exec> <Command>powershell.exe</Command> <Arguments>-WindowStyle Hidden -ExecutionPolicy Bypass -Command "Enable-PnpDevice -InstanceId '$GPU_ID' -Confirm:$false"</Arguments> </Exec> </Actions> </Task>
'@

$disableXML = @'
<Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task\"> <Triggers> <LogonTrigger /> <EventTrigger> <Enabled>true</Enabled> <Subscription> <QueryList>
<Query Id="0" Path="System">
<Select Path="System">
*[System[Provider[@Name='Microsoft-Windows-Kernel-Power'] and EventID=105]] </Select> </Query> </QueryList> </Subscription> </EventTrigger> </Triggers> <Principals>
<Principal id="Author"> <RunLevel>HighestAvailable</RunLevel> </Principal> </Principals> <Settings> <Enabled>true</Enabled> </Settings>
<Actions Context="Author"> <Exec> <Command>powershell.exe</Command> <Arguments>-WindowStyle Hidden -ExecutionPolicy Bypass -Command "Add-Type -AssemblyName System.Windows.Forms; $ac = ([System.Windows.Forms.SystemInformation]::PowerStatus.PowerLineStatus -eq 'Online'); if (-not $ac) { $u = (nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>$null); if ($u -match '^\d+$' -and [int]$u -lt 5) { Disable-PnpDevice -InstanceId '$GPU_ID' -Confirm:$false } }"</Arguments> </Exec> </Actions> </Task>
'@

$enablePath = "$env:TEMP\mux_enable.xml"
$disablePath = "$env:TEMP\mux_disable.xml"

$enableXML | Out-File -Encoding UTF8 $enablePath
$disableXML | Out-File -Encoding UTF8 $disablePath

Write-Host 'Importing tasks...'

schtasks /create /tn "muxless - Enable GPU" /xml $enablePath /ru SYSTEM /f
schtasks /create /tn "muxless - Disable GPU" /xml $disablePath /ru SYSTEM /f

Write-Host ''
Write-Host 'Done.' -ForegroundColor Green
pause
"
