$ErrorActionPreference = "Stop"
Set-Location "C:\zenshi"

# Commit
git add .
git commit -m "fix: resolve compilation errors and update build scripts"

# Add remote and push
git remote set-url origin "https://github.com/XDKILLER4388/zenshi.git"
git branch -M main
git push -u origin main

Write-Host "SUCCESS: https://github.com/XDKILLER4388/zenshi"
