. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Backing Up All Installed Drivers"

$backupPath = "$env:USERPROFILE\Desktop\DriverBackup_$(get-date -f yyyy-MM-dd)"
New-Item -ItemType Directory -Force -Path $backupPath | Out-Null

Write-Host "Exporting drivers to: $backupPath" -ForegroundColor Yellow
Write-Host "This may take a few minutes..." -ForegroundColor White

Export-WindowsDriver -Online -Destination $backupPath

Write-Host "--- Backup Complete ---" -ForegroundColor Green