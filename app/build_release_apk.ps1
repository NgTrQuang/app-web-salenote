# Build APK release — SDK 36 + 16 KB page size (Google Play)
# Yêu cầu: Flutter 3.35+, JDK 17, Android SDK 36
# Xem ANDROID_BUILD.md
#
# Usage:
#   .\build_release_apk.ps1
#   .\build_release_apk.ps1 -Universal

param(
    [switch]$Universal
)

Set-Location $PSScriptRoot

Write-Host "Checking Flutter..." -ForegroundColor Cyan
$flutterVer = flutter --version 2>&1 | Select-String "Flutter" | Select-Object -First 1
Write-Host "  $flutterVer"
$versionMatch = flutter --version 2>&1 | Select-String -Pattern "Flutter (\d+)\.(\d+)" 
if ($versionMatch) {
    $major = [int]$versionMatch.Matches[0].Groups[1].Value
    $minor = [int]$versionMatch.Matches[0].Groups[2].Value
    if ($major -lt 3 -or ($major -eq 3 -and $minor -lt 35)) {
        Write-Host "WARNING: Flutter 3.35+ required for SDK 36 / 16KB. Run: flutter upgrade" -ForegroundColor Yellow
    }
}

flutter pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

if ($Universal) {
    Write-Host "Building universal APK (needs more RAM)..." -ForegroundColor Yellow
    flutter build apk --release --no-tree-shake-icons
} else {
    Write-Host "Building split APKs (arm64 + armeabi-v7a)..." -ForegroundColor Cyan
    flutter build apk --release `
        --split-per-abi `
        --target-platform android-arm,android-arm64 `
        --no-tree-shake-icons
}

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nDone. targetSdk=36, 16KB-ready (AGP 8.9 + NDK r28)" -ForegroundColor Green
    Write-Host "Output: build\app\outputs\flutter-apk\" -ForegroundColor Green
    Get-ChildItem "build\app\outputs\flutter-apk\*.apk" -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Host "  $($_.Name) ($([math]::Round($_.Length/1MB, 1)) MB)"
    }
}
