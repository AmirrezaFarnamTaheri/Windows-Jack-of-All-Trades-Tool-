Write-Host "--- Updating All Software (Security & Performance) ---" -ForegroundColor Cyan
winget upgrade --all --include-unknown --accept-package-agreements --accept-source-agreements

Write-Host "--- Resetting Power Plan to Defaults ---" -ForegroundColor Cyan
powercfg -restoredefaultschemes

Write-Host "--- Optimization Complete ---" -ForegroundColor Green