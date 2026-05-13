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

# 4. Install on Phone
Write-Host "--- Installing on Phone via ADB ---" -ForegroundColor Cyan
$apkPath = "C:\Zenshi\build\app\outputs\flutter-apk\app-release.apk"
if (Test-Path $apkPath) {
    adb install -r $apkPath
    Write-Host "SUCCESS: App installed on phone." -ForegroundColor Green
} else {
    Write-Host "ERROR: APK not found at $apkPath" -ForegroundColor Red
}

Write-Host "--- Deployment Complete ---" -ForegroundColor Green
