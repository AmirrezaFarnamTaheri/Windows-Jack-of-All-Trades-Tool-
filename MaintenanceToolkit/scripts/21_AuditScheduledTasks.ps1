# Check for Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host "Error: This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator." -ForegroundColor Yellow
    if (-not [Console]::IsInputRedirected) { Pause }
    Exit
}
Write-Host "--- Auditing Non-Microsoft Scheduled Tasks ---" -ForegroundColor Cyan

Get-ScheduledTask | Where-Object { $_.Author -notmatch "Microsoft" -and $_.Author -ne $null } | Select-Object TaskName, Author, State | Format-Table -AutoSize

Write-Host "Review this list. If you see 'Author: System' or random names, investigate." -ForegroundColor Yellow