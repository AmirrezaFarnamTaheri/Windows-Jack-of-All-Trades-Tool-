. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Starting Network Stack Reset"

Write-Host "Refreshing IP Address..." -ForegroundColor Yellow
ipconfig /release
ipconfig /renew

Write-Host "Flushing DNS Cache..." -ForegroundColor Yellow
ipconfig /flushdns

Write-Host "Resetting TCP/IP Stack..." -ForegroundColor Yellow
netsh int ip reset

Write-Host "Resetting Winsock Catalog..." -ForegroundColor Yellow
netsh winsock reset

Write-Host "--- Network Reset Complete ---" -ForegroundColor Green
Write-Host "NOTE: You may need to reconnect to your Wi-Fi after restarting." -ForegroundColor Magenta