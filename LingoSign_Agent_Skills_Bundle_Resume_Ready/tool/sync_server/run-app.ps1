param([string]$Device = 'emulator-5554', [int]$Port = 8765, [string]$Flutter = '')
$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$tokenPath = Join-Path $projectRoot '.sync-demo\token.txt'
if (-not (Test-Path -LiteralPath $tokenPath)) { throw 'Chay tool/sync_server/start-server.ps1 trong terminal khac truoc.' }
if (-not $Flutter) { $Flutter = [IO.Path]::GetFullPath((Join-Path $projectRoot '..\..\.tooling\flutter\bin\flutter.bat')) }
if (-not (Test-Path -LiteralPath $Flutter)) { throw 'Khong tim thay Flutter. Truyen -Flutter duong_dan_flutter.bat.' }
$token = (Get-Content -LiteralPath $tokenPath -Raw).Trim()
Push-Location $projectRoot
try {
    & $Flutter run -d $Device "--dart-define=SYNC_URL=http://10.0.2.2:$Port" "--dart-define=SYNC_TOKEN=$token"
    if ($LASTEXITCODE -ne 0) { throw 'Flutter run that bai.' }
} finally { Pop-Location }
