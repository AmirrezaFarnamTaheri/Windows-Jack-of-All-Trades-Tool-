# Check for Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host "Error: This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator." -ForegroundColor Yellow
    if (-not [Console]::IsInputRedirected) { Pause }
    Exit
}
Write-Host "--- Resetting Windows Store & Apps ---" -ForegroundColor Cyan

Write-Host "1. Clearing Store Cache (WSReset)..." -ForegroundColor Yellow
Start-Process "wsreset.exe" -NoNewWindow -Wait

Write-Host "2. Re-registering Store App..." -ForegroundColor Yellow
Get-AppXPackage *WindowsStore* -AllUsers | Foreach {Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml"}

Write-Host "Store Reset Complete. Try opening it now." -ForegroundColor Green