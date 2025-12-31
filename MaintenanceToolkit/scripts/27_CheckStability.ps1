. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "System Stability Check"

$os = Get-WmiObject win32_operatingsystem
$uptime = (Get-Date) - $os.ConvertToDateTime($os.LastBootUpTime)
Write-Host "System Uptime: $($uptime.Days) Days, $($uptime.Hours) Hours" -ForegroundColor Green

Write-Host "`nLast 5 Critical Errors (Blue Screens/Power Loss):" -ForegroundColor Yellow
Get-EventLog -LogName System | Where-Object { $_.EventID -eq 41 } | Select-Object -First 5 TimeGenerated, Message | Format-Table -AutoSize