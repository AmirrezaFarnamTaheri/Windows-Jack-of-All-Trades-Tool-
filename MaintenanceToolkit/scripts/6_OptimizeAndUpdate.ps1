# Check for Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host "Error: This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator." -ForegroundColor Yellow
    if (-not [Console]::IsInputRedirected) { Pause }
    Exit
}
Write-Host "--- Updating All Software (Security & Performance) ---" -ForegroundColor Cyan
winget upgrade --all --include-unknown --accept-package-agreements --accept-source-agreements

Write-Host "--- Resetting Power Plan to Defaults ---" -ForegroundColor Cyan
powercfg -restoredefaultschemes

Write-Host "--- Optimization Complete ---" -ForegroundColor Green