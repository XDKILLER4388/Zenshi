$ErrorActionPreference = "Stop"
Set-Location "C:\Zenshi"

# 1. Git Push
Write-Host "--- Pushing to GitHub ---" -ForegroundColor Cyan
git add .
git commit -m "fix: enable NSFW content, manhua visibility, and filter empty chapters"
git push origin main

# 2. Build APK
Write-Host "--- Building Flutter APK ---" -ForegroundColor Cyan
flutter build apk --release

# 3. Upload to GitHub Releases
Write-Host "--- Uploading to GitHub Releases ---" -ForegroundColor Cyan
python upload_apk.py
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: GitHub upload failed." -ForegroundColor Red
    exit $LASTEXITCODE
}

# 4. Install on Phone
Write-Host "--- Installing on Phone via ADB ---" -ForegroundColor Cyan
$apkPath = "C:\Zenshi\build\app\outputs\flutter-apk\app-release.apk"

# Try to find ADB if not in PATH
$adbPath = "adb"
if (-not (Get-Command "adb" -ErrorAction SilentlyContinue)) {
    $potentialAdb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
    if (Test-Path $potentialAdb) {
        $adbPath = $potentialAdb
        Write-Host "Found ADB at: $adbPath" -ForegroundColor Gray
    } else {
        Write-Host "ERROR: ADB not found. Please install Android Platform Tools or add them to your PATH." -ForegroundColor Red
        exit 1
    }
}

# Check if device is connected
$devices = & $adbPath devices | Select-String -Pattern "\tdevice$"
if (-not $devices) {
    Write-Host "ERROR: No authorized device found. Please check USB debugging and authorize the computer." -ForegroundColor Red
    Write-Host "Current devices status:"
    & $adbPath devices
} else {
    if (Test-Path $apkPath) {
        Write-Host "Installing APK..."
        & $adbPath install -r -d $apkPath
        if ($LASTEXITCODE -eq 0) {
            Write-Host "SUCCESS: App installed on phone." -ForegroundColor Green
            Write-Host "Launching app..."
            & $adbPath shell am start -n com.zenshi.zenshi/.MainActivity
        } else {
            Write-Host "ERROR: ADB installation failed. Try uninstalling the old version first." -ForegroundColor Red
        }
    } else {
        Write-Host "ERROR: APK not found at $apkPath" -ForegroundColor Red
    }
}

Write-Host "--- Deployment Complete ---" -ForegroundColor Green
