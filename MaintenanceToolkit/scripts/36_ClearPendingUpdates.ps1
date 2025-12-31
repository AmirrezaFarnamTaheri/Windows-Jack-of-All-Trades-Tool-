# Check for Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host "Error: This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator." -ForegroundColor Yellow
    if (-not [Console]::IsInputRedirected) { Pause }
    Exit
}
Write-Host "--- Clearing Pending Update Flags ---" -ForegroundColor Cyan
Remove-Item -Path "C:\Windows\WinSxS\pending.xml" -Force -ErrorAction SilentlyContinue

$wusettings = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update"
Set-ItemProperty -Path $wusettings -Name "AUOptions" -Value 2 -ErrorAction SilentlyContinue

Write-Host "Pending flags cleared. Please restart." -ForegroundColor Green