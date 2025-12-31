# Check for Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host "Error: This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator." -ForegroundColor Yellow
    if (-not [Console]::IsInputRedirected) { Pause }
    Exit
}
Write-Host "--- Auditing Local User Accounts ---" -ForegroundColor Cyan

Get-LocalUser | Select-Object Name, Enabled, LastLogon, Description | Format-Table -AutoSize

Write-Host "Check for accounts you did not create." -ForegroundColor Yellow
Write-Host "'Guest' and 'DefaultAccount' are normal if disabled (False)." -ForegroundColor DarkGray