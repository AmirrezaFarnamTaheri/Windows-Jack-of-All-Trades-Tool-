. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Fixing Stuck Printer Queue"

Write-Host "Stopping Spooler Service..." -ForegroundColor Yellow
Stop-Service spooler -Force

Write-Host "Deleting temporary print files..." -ForegroundColor Yellow
Remove-Item -Path "C:\Windows\System32\spool\PRINTERS\*.*" -Force -ErrorAction SilentlyContinue

Write-Host "Restarting Spooler Service..." -ForegroundColor Green
Start-Service spooler

Write-Host "Print queue cleared. Try printing again." -ForegroundColor Green