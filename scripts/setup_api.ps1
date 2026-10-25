# Create the model-compatible backend runtime without changing the old venv.
param([string]$Python312 = '')
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
if (-not $Python312) {
  $Python312 = Join-Path $env:LOCALAPPDATA 'Programs\Python\Python312\python.exe'
}
if (-not (Test-Path -LiteralPath $Python312)) {
  throw 'Python 3.12 is required. Install it or pass -Python312 with its full path.'
}
& $Python312 -c 'import sys; assert sys.version_info[:2] == (3, 12), "Use Python 3.12"'
if ($LASTEXITCODE -ne 0) { throw 'A Python 3.12 interpreter is required.' }
$venv = Join-Path $root '.venv-api'
$python = Join-Path $venv 'Scripts\python.exe'
if (-not (Test-Path -LiteralPath $python)) {
  & $Python312 -m venv $venv
  if ($LASTEXITCODE -ne 0) { throw 'Could not create the API environment.' }
}
& $python -c 'import sys; assert sys.version_info[:2] == (3, 12), "Existing environment is not Python 3.12"'
if ($LASTEXITCODE -ne 0) { throw 'The existing .venv-api must use Python 3.12.' }
& $python -m pip --version *> $null
if ($LASTEXITCODE -ne 0) {
  & $python -m ensurepip --upgrade
  if ($LASTEXITCODE -ne 0) { throw 'Could not bootstrap pip in the API environment.' }
}
$lock = Join-Path $root 'requirements-api.lock.txt'
$requirements = Join-Path $root 'requirements.txt'
if (Test-Path -LiteralPath $lock) { $requirements = $lock }
& $python -m pip install --only-binary=:all: -r $requirements
if ($LASTEXITCODE -ne 0) { throw 'Could not install API dependencies.' }
& $python -m pip check
if ($LASTEXITCODE -ne 0) { throw 'API dependencies are inconsistent.' }
Write-Host "API environment ready: $python"
