# Check for Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host "Error: This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator." -ForegroundColor Yellow
    if (-not [Console]::IsInputRedirected) { Pause }
    Exit
}
Write-Host "--- Resetting Windows Update Components ---" -ForegroundColor Cyan
Write-Host "This fixes stuck updates and download errors." -ForegroundColor Yellow

Write-Host "Stopping Services..." -ForegroundColor White
Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
Stop-Service cryptSvc -Force -ErrorAction SilentlyContinue
Stop-Service bits -Force -ErrorAction SilentlyContinue
Stop-Service msiserver -Force -ErrorAction SilentlyContinue

Write-Host "Renaming SoftwareDistribution Folder..." -ForegroundColor White
Rename-Item -Path "C:\Windows\SoftwareDistribution" -NewName "SoftwareDistribution.old" -ErrorAction SilentlyContinue

Write-Host "Renaming Catroot2 Folder..." -ForegroundColor White
Rename-Item -Path "C:\Windows\System32\catroot2" -NewName "catroot2.old" -ErrorAction SilentlyContinue

Write-Host "Restarting Services..." -ForegroundColor White
Start-Service wuauserv
Start-Service cryptSvc
Start-Service bits
Start-Service msiserver

Write-Host "--- Windows Update Reset Complete ---" -ForegroundColor Green