# Check for Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host "Error: This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator." -ForegroundColor Yellow
    if (-not [Console]::IsInputRedirected) { Pause }
    Exit
}
Write-Host "--- Restarting Audio Services ---" -ForegroundColor Cyan

Stop-Service "Audiosrv" -Force
Stop-Service "AudioEndpointBuilder" -Force

Start-Service "AudioEndpointBuilder"
Start-Service "Audiosrv"

Write-Host "Audio Stack Restarted. Test your sound now." -ForegroundColor Green