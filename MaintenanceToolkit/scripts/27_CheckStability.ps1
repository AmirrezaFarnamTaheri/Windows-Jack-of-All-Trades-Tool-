# Check for Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host "Error: This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator." -ForegroundColor Yellow
    if (-not [Console]::IsInputRedirected) { Pause }
    Exit
}
Write-Host "--- System Stability Check ---" -ForegroundColor Cyan

$os = Get-WmiObject win32_operatingsystem
$uptime = (Get-Date) - $os.ConvertToDateTime($os.LastBootUpTime)
Write-Host "System Uptime: $($uptime.Days) Days, $($uptime.Hours) Hours" -ForegroundColor Green

Write-Host "`nLast 5 Critical Errors (Blue Screens/Power Loss):" -ForegroundColor Yellow
Get-EventLog -LogName System | Where-Object { $_.EventID -eq 41 } | Select-Object -First 5 TimeGenerated, Message | Format-Table -AutoSize