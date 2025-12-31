# Check for Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host "Error: This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator." -ForegroundColor Yellow
    if (-not [Console]::IsInputRedirected) { Pause }
    Exit
}
Write-Host "--- Rebuilding Font Cache ---" -ForegroundColor Cyan

Stop-Service "FontCache" -Force -ErrorAction SilentlyContinue

$fontCachePath = "C:\Windows\ServiceProfiles\LocalService\AppData\Local\FontCache"
Remove-Item -Path "$fontCachePath\*.dat" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "C:\Windows\System32\FNTCACHE.DAT" -Force -ErrorAction SilentlyContinue

Write-Host "Cache cleared. Starting Font Service..." -ForegroundColor Yellow
Start-Service "FontCache"

Write-Host "--- Fonts Reset ---" -ForegroundColor Green
Write-Host "You must restart your PC for text to render correctly." -ForegroundColor Magenta