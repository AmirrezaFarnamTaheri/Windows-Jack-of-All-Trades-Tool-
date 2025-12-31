# Check for Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host "Error: This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator." -ForegroundColor Yellow
    if (-not [Console]::IsInputRedirected) { Pause }
    Exit
}
Write-Host "--- Generating Battery Health Report ---" -ForegroundColor Cyan

$reportPath = "$env:USERPROFILE\Desktop\battery_report.html"
powercfg /batteryreport /output $reportPath

Write-Host "Report generated successfully." -ForegroundColor Green
Write-Host "Opening report in your default browser..." -ForegroundColor Yellow
Start-Process $reportPath