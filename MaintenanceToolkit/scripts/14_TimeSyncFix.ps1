. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Fixing Windows Time Synchronization"
Get-SystemSummary
Write-Section "Execution"

try {
    Write-Log "Stopping Time Service..."
    Stop-ServiceSafe "w32time" -ErrorAction SilentlyContinue

    Write-Log "Unregistering/Registering Time Service..."
    w32tm /unregister
    w32tm /register
    Start-Service w32time

    Write-Log "Resyncing..."
    w32tm /resync /nowait

    Show-Success "Time Sync Repair Complete."
} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
