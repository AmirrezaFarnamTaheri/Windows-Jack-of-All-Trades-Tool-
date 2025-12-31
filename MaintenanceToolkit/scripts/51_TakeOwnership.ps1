# Check for Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host "Error: This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator." -ForegroundColor Yellow
    if (-not [Console]::IsInputRedirected) { Pause }
    Exit
}
Write-Host "--- Fix 'Access Denied' Errors ---" -ForegroundColor Cyan
$path = Read-Host "Enter folder path to unlock"
$path = $path -replace '"', ''

if (Test-Path $path) {
    Write-Host "Taking Ownership..." -ForegroundColor Yellow
    takeown /f "$path" /r /d y

    Write-Host "Granting Permissions..." -ForegroundColor Yellow
    icacls "$path" /grant "$($env:USERNAME):(OI)(CI)F" /t

    Write-Host "Folder Unlocked." -ForegroundColor Green
}