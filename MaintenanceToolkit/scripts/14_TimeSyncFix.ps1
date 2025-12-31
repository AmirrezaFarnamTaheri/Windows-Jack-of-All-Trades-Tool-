Write-Host "--- Resynchronizing System Clock ---" -ForegroundColor Cyan

Write-Host "Restarting Time Service..." -ForegroundColor Yellow
Restart-Service W32Time

Write-Host "Contacting Time Server..." -ForegroundColor Yellow
w32tm /resync

if ($?) {
    Write-Host "Success: Time is now perfectly synced." -ForegroundColor Green
} else {
    Write-Host "Error: Could not sync. Check internet connection." -ForegroundColor Red
}