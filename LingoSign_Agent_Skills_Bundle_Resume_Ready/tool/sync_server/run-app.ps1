param([string]$Device = 'emulator-5554', [int]$Port = 8765, [string]$Flutter = '', [switch]$NoAttach, [switch]$Attach, [switch]$Reinstall)
$ErrorActionPreference = 'Stop'
if ($Attach -and $NoAttach) { throw 'Chi chon -Attach hoac -NoAttach.' }
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$sdkRoot = if ($env:ANDROID_SDK_ROOT) { $env:ANDROID_SDK_ROOT } elseif ($env:ANDROID_HOME) { $env:ANDROID_HOME } else { Join-Path $env:LOCALAPPDATA 'Android\Sdk' }
$adb = Join-Path $sdkRoot 'platform-tools\adb.exe'
if (-not (Test-Path -LiteralPath $adb)) { throw 'Khong tim thay adb.exe. Kiem tra Android SDK.' }
$package = 'com.lingosign.lingosign_ai'
$installedPackages = & $adb -s $Device shell pm list packages $package
if ($LASTEXITCODE -ne 0) { throw 'Chua ket noi duoc Android. Mo va doi may ao khoi dong xong.' }
$needsInstall = $Reinstall -or ($installedPackages -notcontains "package:$package")

if ($needsInstall -or $Attach) {
    $firebaseConfig = Join-Path $projectRoot '.sync-demo\firebase-defines.json'
    if (Test-Path -LiteralPath $firebaseConfig) {
        $defines = @("--dart-define-from-file=$firebaseConfig")
    } else {
        $tokenPath = Join-Path $projectRoot '.sync-demo\token.txt'
        if (-not (Test-Path -LiteralPath $tokenPath)) { throw 'Cau hinh Firebase hoac chay tool/sync_server/start-server.ps1 truoc.' }
        $token = (Get-Content -LiteralPath $tokenPath -Raw).Trim()
        $defines = @("--dart-define=SYNC_URL=http://10.0.2.2:$Port", "--dart-define=SYNC_TOKEN=$token")
    }
    if (-not $Flutter) { $Flutter = [IO.Path]::GetFullPath((Join-Path $projectRoot '..\..\.tooling\flutter\bin\flutter.bat')) }
    if (-not (Test-Path -LiteralPath $Flutter)) { throw 'Khong tim thay Flutter. Truyen -Flutter duong_dan_flutter.bat.' }
}

Push-Location $projectRoot
try {
    if ($needsInstall) {
        $abi = (& $adb -s $Device shell getprop ro.product.cpu.abi | Out-String).Trim()
        if ($LASTEXITCODE -ne 0) { throw 'Chua ket noi duoc Android. Mo may ao truoc.' }
        $target = switch ($abi) { 'x86_64' { 'android-x64' } 'arm64-v8a' { 'android-arm64' } 'armeabi-v7a' { 'android-arm' } default { throw "ABI khong duoc ho tro: $abi" } }
        & $Flutter build apk --debug --split-per-abi --target-platform $target @defines
        if ($LASTEXITCODE -ne 0) { throw 'Build APK that bai.' }
        $apk = Join-Path $projectRoot "build\app\outputs\flutter-apk\app-$abi-debug.apk"
        if (-not (Test-Path -LiteralPath $apk)) { throw 'Khong tim thay APK dung kien truc.' }
        # Install directly: unlike flutter run, failure never triggers auto-uninstall.
        & $adb -s $Device install -r $apk
        if ($LASTEXITCODE -ne 0) { throw 'Cai APK that bai. Khong tu go app. Kiem tra dung luong may ao neu co INSUFFICIENT_STORAGE.' }
    } else {
        Write-Host 'Dung ban da cai tren thiet bi.'
    }
    & $adb -s $Device shell am start -n "$package/.MainActivity"
    if ($LASTEXITCODE -ne 0) { throw 'Khong mo duoc app.' }
    Write-Host 'App da mo. Dung -Reinstall khi can build va cai ban moi.'
    if ($Attach) {
        # Use the exact kernel just built into this APK, not attach's independent
        # incremental cache (which can retain invalid package paths on Windows).
        $kernel = Join-Path $projectRoot 'build\app\intermediates\flutter\debug\flutter_assets\kernel_blob.bin'
        if (-not (Test-Path -LiteralPath $kernel)) { throw 'Khong tim thay kernel tu APK vua build.' }
        & $Flutter attach -d $Device "--initialize-from-dill=$kernel" @defines
        if ($LASTEXITCODE -ne 0) { throw 'App da mo nhung Flutter attach that bai.' }
    }
} finally { Pop-Location }
