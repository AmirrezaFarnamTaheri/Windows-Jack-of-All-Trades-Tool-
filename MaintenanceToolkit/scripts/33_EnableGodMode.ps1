# Check for Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host "Error: This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator." -ForegroundColor Yellow
    if (-not [Console]::IsInputRedirected) { Pause }
    Exit
}
Write-Host "--- Activating God Mode ---" -ForegroundColor Cyan

$desktop = [Environment]::GetFolderPath("Desktop")
$godModePath = "$desktop\GodMode.{ED7BA470-8E54-465E-825C-99712043E01C}"

if (-not (Test-Path $godModePath)) {
    New-Item -Path $godModePath -ItemType Directory -Force | Out-Null
    Write-Host "God Mode icon created on your Desktop." -ForegroundColor Green
} else {
    Write-Host "God Mode already exists." -ForegroundColor Yellow
}