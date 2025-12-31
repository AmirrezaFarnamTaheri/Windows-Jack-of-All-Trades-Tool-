Write-Host "--- Creating System Restore Point ---" -ForegroundColor Cyan
try {
    Checkpoint-Computer -Description "CleanUp_PreStart" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
    Write-Host "Success: Restore Point 'CleanUp_PreStart' created." -ForegroundColor Green
}
catch {
    Write-Host "Error: Could not create Restore Point. Ensure you are running as Administrator." -ForegroundColor Red
    Write-Host "You may also need to enable System Protection in Control Panel." -ForegroundColor Yellow
}