param([Parameter(Mandatory)][string]$GoogleServicesJson)
$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$config = Get-Content -LiteralPath $GoogleServicesJson -Raw | ConvertFrom-Json
$clients = @($config.client | Where-Object {
    $_.client_info.android_client_info.package_name -eq 'com.lingosign.lingosign_ai'
})
if ($clients.Count -ne 1) { throw 'JSON phai chua dung mot Android app com.lingosign.lingosign_ai.' }
$defines = @{
    FIREBASE_API_KEY = @($clients[0].api_key)[0].current_key
    FIREBASE_APP_ID = $clients[0].client_info.mobilesdk_app_id
    FIREBASE_PROJECT_ID = $config.project_info.project_id
    FIREBASE_SENDER_ID = $config.project_info.project_number
}
foreach ($value in $defines.Values) {
    if ([string]::IsNullOrWhiteSpace($value)) { throw 'Cau hinh Firebase thieu truong bat buoc.' }
}
$folder = Join-Path $projectRoot '.sync-demo'
[void](New-Item -Path $folder -ItemType Directory -Force)
$output = Join-Path $folder 'firebase-defines.json'
[IO.File]::WriteAllText($output, ($defines | ConvertTo-Json), [Text.UTF8Encoding]::new($false))
Write-Host 'Da cau hinh Firebase. Chay run-app.ps1 -Reinstall de cai ban moi.'
