Write-Host "--- Rebuilding Font Cache ---" -ForegroundColor Cyan

Stop-Service "FontCache" -Force -ErrorAction SilentlyContinue

$fontCachePath = "C:\Windows\ServiceProfiles\LocalService\AppData\Local\FontCache"
Remove-Item -Path "$fontCachePath\*.dat" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "C:\Windows\System32\FNTCACHE.DAT" -Force -ErrorAction SilentlyContinue

Write-Host "Cache cleared. Starting Font Service..." -ForegroundColor Yellow
Start-Service "FontCache"

Write-Host "--- Fonts Reset ---" -ForegroundColor Green
Write-Host "You must restart your PC for text to render correctly." -ForegroundColor Magenta