# Check for Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host "Error: This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator." -ForegroundColor Yellow
    if (-not [Console]::IsInputRedirected) { Pause }
    Exit
}
Write-Host "--- Clearing Clipboard History ---" -ForegroundColor Cyan

Set-Clipboard -Value $null

Write-Host "Clearing History..."
try {
    # Method to restart Clipboard User Service
    Get-Service | Where-Object {$_.Name -like "cbdhsvc*"} | Restart-Service -Force -ErrorAction SilentlyContinue
    Write-Host "Clipboard & History cleared." -ForegroundColor Green
} catch {
    Write-Host "Could not access Clipboard Service." -ForegroundColor Red
}