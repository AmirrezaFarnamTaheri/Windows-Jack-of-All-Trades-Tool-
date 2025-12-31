# Check for Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host "Error: This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator." -ForegroundColor Yellow
    if (-not [Console]::IsInputRedirected) { Pause }
    Exit
}
Write-Host "--- Optimizing TCP Receive Window ---" -ForegroundColor Cyan

$current = Get-NetTCPSetting | Select-Object SettingName, AutoTuningLevelLocal
Write-Host "Current Setting: $($current.AutoTuningLevelLocal)"

netsh int tcp set global autotuninglevel=normal

Write-Host "Network Stack Optimized." -ForegroundColor Green