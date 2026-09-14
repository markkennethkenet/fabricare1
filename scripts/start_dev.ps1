# Start FabriCare API + USB port forward for a physical Android phone.
# Usage: .\scripts\start_dev.ps1

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$adb = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'
$python = Join-Path (Split-Path -Parent $root) '.venv\Scripts\python.exe'
$api = Join-Path $root 'fabricare_api.py'

if (-not (Test-Path $adb)) {
  Write-Host 'adb not found. Install Android SDK platform-tools or use Wi-Fi mode in lib/config/dev_api_host.dart'
  exit 1
}

Write-Host 'Setting up adb reverse tcp:5000 -> PC:5000 ...'
& $adb reverse tcp:5000 tcp:5000
& $adb reverse --list

Write-Host 'Starting FabriCare API on http://127.0.0.1:5000 ...'
Set-Location $root
& $python $api
