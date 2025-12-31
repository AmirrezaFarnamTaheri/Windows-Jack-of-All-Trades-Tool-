# Check for Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host "Error: This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator." -ForegroundColor Yellow
    if (-not [Console]::IsInputRedirected) { Pause }
    Exit
}
Write-Host "--- Resynchronizing System Clock ---" -ForegroundColor Cyan

Write-Host "Restarting Time Service..." -ForegroundColor Yellow
Restart-Service W32Time

Write-Host "Contacting Time Server..." -ForegroundColor Yellow
w32tm /resync

if ($?) {
    Write-Host "Success: Time is now perfectly synced." -ForegroundColor Green
} else {
    Write-Host "Error: Could not sync. Check internet connection." -ForegroundColor Red
}