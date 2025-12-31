# Check for Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host "Error: This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator." -ForegroundColor Yellow
    if (-not [Console]::IsInputRedirected) { Pause }
    Exit
}
Write-Host "--- Clearing All Windows Event Logs ---" -ForegroundColor Cyan

$logs = Get-EventLog -LogName *
foreach ($log in $logs) {
    $logName = $log.Log
    try {
        Write-Host "Clearing $logName..." -ForegroundColor Yellow
        Clear-EventLog -LogName $logName -ErrorAction Stop
    }
    catch {
        Write-Host "Skipped $logName (Locked or Empty)" -ForegroundColor DarkGray
    }
}

Write-Host "--- All Logs Cleared ---" -ForegroundColor Green