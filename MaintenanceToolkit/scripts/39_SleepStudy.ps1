# Check for Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host "Error: This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator." -ForegroundColor Yellow
    if (-not [Console]::IsInputRedirected) { Pause }
    Exit
}
Write-Host "--- Generating System Sleep Study ---" -ForegroundColor Cyan
Write-Host "This analyzes battery drain while the computer is sleeping." -ForegroundColor Yellow

$path = "$env:USERPROFILE\Desktop\SleepStudy.html"
powercfg /sleepstudy /output "$path" /duration 3

Write-Host "Report generated on Desktop." -ForegroundColor Green
Start-Process "$path"