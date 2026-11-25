param([string]$Project = 'danentang-f803c')
$ErrorActionPreference = 'Stop'
& npx --yes firebase-tools --version
if ($LASTEXITCODE -ne 0) { throw 'Khong tim thay Firebase CLI.' }
$cache = Join-Path $env:LOCALAPPDATA 'npm-cache/_npx'
$cli = Get-ChildItem -LiteralPath $cache -Directory | ForEach-Object {
  $candidate = Join-Path $_.FullName 'node_modules/firebase-tools'
  if (Test-Path -LiteralPath (Join-Path $candidate 'lib/auth.js')) { $candidate }
} | Select-Object -First 1
if (-not $cli) { throw 'Khong tim thay Firebase CLI. Chay npm exec firebase-tools -- --version truoc.' }
& node (Join-Path $PSScriptRoot 'sync-auth-users.cjs') $cli $Project
if ($LASTEXITCODE -ne 0) { throw 'Dong bo tai khoan that bai. Kiem tra firebase login va quyen du an.' }
