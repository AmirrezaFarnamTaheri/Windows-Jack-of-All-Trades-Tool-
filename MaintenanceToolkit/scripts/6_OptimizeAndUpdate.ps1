. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Updating All Software (Security & Performance)"
winget upgrade --all --include-unknown --accept-package-agreements --accept-source-agreements

Write-Header "Resetting Power Plan to Defaults"
powercfg -restoredefaultschemes

Write-Host "--- Optimization Complete ---" -ForegroundColor Green