# Check for Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host "Error: This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator." -ForegroundColor Yellow
    if (-not [Console]::IsInputRedirected) { Pause }
    Exit
}
Write-Host "--- Starting Network Stack Reset ---" -ForegroundColor Cyan

Write-Host "Refreshing IP Address..." -ForegroundColor Yellow
ipconfig /release
ipconfig /renew

Write-Host "Flushing DNS Cache..." -ForegroundColor Yellow
ipconfig /flushdns

Write-Host "Resetting TCP/IP Stack..." -ForegroundColor Yellow
netsh int ip reset

Write-Host "Resetting Winsock Catalog..." -ForegroundColor Yellow
netsh winsock reset

Write-Host "--- Network Reset Complete ---" -ForegroundColor Green
Write-Host "NOTE: You may need to reconnect to your Wi-Fi after restarting." -ForegroundColor Magenta