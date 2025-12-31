# Check for Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host "Error: This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator." -ForegroundColor Yellow
    if (-not [Console]::IsInputRedirected) { Pause }
    Exit
}
Write-Host "--- Retrieving Latest Disk Scan Results ---" -ForegroundColor Cyan

$log = Get-EventLog -LogName Application -Source "Wininit" -Newest 1
if ($log) {
    Write-Host "Date: $($log.TimeGenerated)" -ForegroundColor Yellow
    Write-Host "Message:"
    Write-Host $log.Message -ForegroundColor White
} else {
    Write-Host "No recent CheckDisk logs found." -ForegroundColor Red
}