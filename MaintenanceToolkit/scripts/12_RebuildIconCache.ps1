Write-Host "--- Rebuilding Icon and Thumbnail Cache ---" -ForegroundColor Cyan
Write-Host "Your screen will flash black and the taskbar will disappear momentarily." -ForegroundColor Yellow

Stop-Process -Name explorer -Force
Start-Sleep -Seconds 2

$iconCache = "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\iconcache*"
$thumbCache = "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache*"

Remove-Item -Path $iconCache -Force -ErrorAction SilentlyContinue
Remove-Item -Path $thumbCache -Force -ErrorAction SilentlyContinue

Write-Host "Caches deleted. Restarting Explorer..." -ForegroundColor Green
Start-Process explorer

Write-Host "--- Visual Cache Rebuilt ---" -ForegroundColor Green