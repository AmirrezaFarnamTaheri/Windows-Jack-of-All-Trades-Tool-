# Check for Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host "Error: This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator." -ForegroundColor Yellow
    if (-not [Console]::IsInputRedirected) { Pause }
    Exit
}
$min = Read-Host "Shut down in how many minutes? (0 to cancel)"

if ($min -gt 0) {
    $sec = [int]$min * 60
    shutdown /s /t $sec
    Write-Host "Timer set for $min minutes." -ForegroundColor Green
    Write-Host "(Run 'shutdown /a' in CMD to cancel)" -ForegroundColor Yellow
}