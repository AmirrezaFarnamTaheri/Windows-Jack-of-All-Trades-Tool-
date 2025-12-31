# Check for Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host "Error: This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator." -ForegroundColor Yellow
    if (-not [Console]::IsInputRedirected) { Pause }
    Exit
}
Write-Host "--- Installing Essential Apps ---" -ForegroundColor Cyan
$apps = @("Google.Chrome", "VideoLAN.VLC", "7zip.7zip", "Notepad++.Notepad++", "Discord.Discord")

foreach ($app in $apps) {
    Write-Host "Installing $app..." -ForegroundColor Yellow
    winget install --id $app -e --silent --accept-package-agreements --accept-source-agreements
}
Write-Host "All Essentials Installed." -ForegroundColor Green