param([int]$Port = 8765)
$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$demoDirectory = Join-Path $projectRoot '.sync-demo'
New-Item -ItemType Directory -Force -Path $demoDirectory | Out-Null
$tokenPath = Join-Path $demoDirectory 'token.txt'
if (-not (Test-Path -LiteralPath $tokenPath)) {
    $bytes = New-Object byte[] 32
    $generator = [Security.Cryptography.RandomNumberGenerator]::Create()
    try { $generator.GetBytes($bytes) } finally { $generator.Dispose() }
    [Convert]::ToBase64String($bytes) | Set-Content -LiteralPath $tokenPath -Encoding ascii
}
$previousToken = $env:SYNC_TOKEN
try {
    $env:SYNC_TOKEN = (Get-Content -LiteralPath $tokenPath -Raw).Trim()
    Write-Host "May chu demo dang chay tren 127.0.0.1:$Port. Dung bang Ctrl+C."
    & python (Join-Path $PSScriptRoot 'server.py') --db (Join-Path $demoDirectory 'server.sqlite') --port $Port
    if ($LASTEXITCODE -ne 0) { throw 'Khong khoi dong duoc may chu demo.' }
} finally { $env:SYNC_TOKEN = $previousToken }
