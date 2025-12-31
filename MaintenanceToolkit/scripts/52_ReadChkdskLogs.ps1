. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Retrieving Latest Disk Scan Results"

$log = Get-EventLog -LogName Application -Source "Wininit" -Newest 1
if ($log) {
    Write-Host "Date: $($log.TimeGenerated)" -ForegroundColor Yellow
    Write-Host "Message:"
    Write-Host $log.Message -ForegroundColor White
} else {
    Write-Host "No recent CheckDisk logs found." -ForegroundColor Red
}