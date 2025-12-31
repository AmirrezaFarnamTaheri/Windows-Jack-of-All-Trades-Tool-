Write-Host "--- Generating Battery Health Report ---" -ForegroundColor Cyan

$reportPath = "$env:USERPROFILE\Desktop\battery_report.html"
powercfg /batteryreport /output $reportPath

Write-Host "Report generated successfully." -ForegroundColor Green
Write-Host "Opening report in your default browser..." -ForegroundColor Yellow
Start-Process $reportPath