# Check for Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host "Error: This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator." -ForegroundColor Yellow
    if (-not [Console]::IsInputRedirected) { Pause }
    Exit
}
Write-Host "--- EMERGENCY RESTART ---" -ForegroundColor Red
Write-Host "This will not save open documents."
$confirm = Read-Host "Type 'RESTART' to confirm"

if ($confirm -eq 'RESTART') {
    shutdown /r /f /t 0
}