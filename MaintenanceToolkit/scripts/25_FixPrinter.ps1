# Check for Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host "Error: This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator." -ForegroundColor Yellow
    if (-not [Console]::IsInputRedirected) { Pause }
    Exit
}
Write-Host "--- Fixing Stuck Printer Queue ---" -ForegroundColor Cyan

Write-Host "Stopping Spooler Service..." -ForegroundColor Yellow
Stop-Service spooler -Force

Write-Host "Deleting temporary print files..." -ForegroundColor Yellow
Remove-Item -Path "C:\Windows\System32\spool\PRINTERS\*.*" -Force -ErrorAction SilentlyContinue

Write-Host "Restarting Spooler Service..." -ForegroundColor Green
Start-Service spooler

Write-Host "Print queue cleared. Try printing again." -ForegroundColor Green