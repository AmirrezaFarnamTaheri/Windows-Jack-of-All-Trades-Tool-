Write-Host "--- Clearing Clipboard History ---" -ForegroundColor Cyan

Set-Clipboard -Value $null

Write-Host "Clearing History..."
try {
    # Method to restart Clipboard User Service
    Get-Service | Where-Object {$_.Name -like "cbdhsvc*"} | Restart-Service -Force -ErrorAction SilentlyContinue
    Write-Host "Clipboard & History cleared." -ForegroundColor Green
} catch {
    Write-Host "Could not access Clipboard Service." -ForegroundColor Red
}