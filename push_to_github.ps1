$ErrorActionPreference = "Stop"
Set-Location "C:\zenshi"

# Commit
git commit -m "feat: initial Zenshi manga reader - Flutter 3.32, Riverpod, Drift, Supabase, 16 screens, extension sandbox, offline-first"

# Add remote and push
git remote add origin "https://XDKILLER4388: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@github.com/XDKILLER4388/zenshi.git"
git branch -M main
git push -u origin main

Write-Host "SUCCESS: https://github.com/XDKILLER4388/zenshi"
