. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Reset Bluetooth Service"
Get-SystemSummary
Write-Section "Execution"

try {
    Write-Log "Stopping Bluetooth Services..." "Yellow"
    $btServices = Get-Service -Name "bthserv", "BluetoothUserService*" -ErrorAction SilentlyContinue
    foreach ($svc in $btServices) {
        Stop-ServiceSafe $svc.Name -ErrorAction SilentlyContinue
    }

    Start-Sleep -Seconds 2

    Write-Log "Starting Bluetooth Services..." "Cyan"
    foreach ($svc in $btServices) {
        Start-Service $svc.Name -ErrorAction SilentlyContinue
    }

    $notRunning = $btServices | Where-Object { (Get-Service $_.Name -ErrorAction SilentlyContinue).Status -ne 'Running' }
    if ($notRunning) {
        Show-Error ("Some Bluetooth services failed to start: " + (($notRunning | Select-Object -ExpandProperty Name) -join ", "))
    } else {
        Show-Success "Bluetooth Services Restarted."
    }

} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
