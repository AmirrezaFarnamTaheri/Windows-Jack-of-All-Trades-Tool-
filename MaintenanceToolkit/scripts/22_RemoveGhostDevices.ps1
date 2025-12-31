# Check for Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host "Error: This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator." -ForegroundColor Yellow
    if (-not [Console]::IsInputRedirected) { Pause }
    Exit
}
Write-Host "--- Checking for Unused (Ghost) Devices ---" -ForegroundColor Cyan

Write-Host "Enabling 'Show Non-Present Devices' variable..." -ForegroundColor Yellow
[Environment]::SetEnvironmentVariable("DEVMGR_SHOW_NONPRESENT_DEVICES", "1", "User")

Write-Host "Opening Device Manager..." -ForegroundColor Green
Write-Host "ACTION: Go to 'View' -> 'Show hidden devices'. Grayed out icons are ghost devices." -ForegroundColor Magenta
devmgmt.msc