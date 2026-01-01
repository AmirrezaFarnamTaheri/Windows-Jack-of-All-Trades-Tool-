. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Reset Bluetooth Service"
Get-SystemSummary
Write-Section "Execution"

try {
    Write-Log "Stopping Bluetooth Services..." "Yellow"
    Stop-ServiceSafe "bthserv" -ErrorAction SilentlyContinue
    Stop-ServiceSafe "BluetoothUserService*" -ErrorAction SilentlyContinue

    Start-Sleep -Seconds 2

    Write-Log "Starting Bluetooth Services..." "Cyan"
    Start-Service "bthserv" -ErrorAction SilentlyContinue

    Show-Success "Bluetooth Services Restarted."

} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
