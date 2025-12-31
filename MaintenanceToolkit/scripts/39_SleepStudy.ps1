. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Generating System Sleep Study"
Write-Host "This analyzes battery drain while the computer is sleeping." -ForegroundColor Yellow

$path = "$env:USERPROFILE\Desktop\SleepStudy.html"
powercfg /sleepstudy /output "$path" /duration 3

Write-Host "Report generated on Desktop." -ForegroundColor Green
Start-Process "$path"