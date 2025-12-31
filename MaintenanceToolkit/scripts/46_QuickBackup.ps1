Write-Host "--- Quick Mirror Backup (Robocopy) ---" -ForegroundColor Cyan

$source = "$env:USERPROFILE\Documents"
$dest = Read-Host "Enter Destination Drive Letter (e.g. E:\Backup)"

if (-not (Test-Path $dest)) { New-Item -ItemType Directory -Path $dest -Force | Out-Null }

robocopy "$source" "$dest" /MIR /XO /R:1 /W:1 /MT:8

Write-Host "Backup Complete." -ForegroundColor Green