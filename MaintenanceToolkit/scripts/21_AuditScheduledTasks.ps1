. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Auditing Non-Microsoft Scheduled Tasks"

Get-ScheduledTask | Where-Object { $_.Author -notmatch "Microsoft" -and $_.Author -ne $null } | Select-Object TaskName, Author, State | Format-Table -AutoSize

Write-Host "Review this list. If you see 'Author: System' or random names, investigate." -ForegroundColor Yellow