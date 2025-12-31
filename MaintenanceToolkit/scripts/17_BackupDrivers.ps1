# Check for Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host "Error: This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator." -ForegroundColor Yellow
    if (-not [Console]::IsInputRedirected) { Pause }
    Exit
}
Write-Host "--- Backing Up All Installed Drivers ---" -ForegroundColor Cyan

$backupPath = "$env:USERPROFILE\Desktop\DriverBackup_$(get-date -f yyyy-MM-dd)"
New-Item -ItemType Directory -Force -Path $backupPath | Out-Null

Write-Host "Exporting drivers to: $backupPath" -ForegroundColor Yellow
Write-Host "This may take a few minutes..." -ForegroundColor White

Export-WindowsDriver -Online -Destination $backupPath

Write-Host "--- Backup Complete ---" -ForegroundColor Green