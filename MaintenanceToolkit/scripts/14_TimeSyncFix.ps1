. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Fixing Windows Time Synchronization"

try {
    Write-Log "Stopping Time Service..."
    Stop-ServiceSafe "w32time" -ErrorAction SilentlyContinue

    Write-Log "Unregistering/Registering Time Service..."
    w32tm /unregister
    w32tm /register
    Start-Service w32time

    Write-Log "Resyncing..."
    w32tm /resync /nowait

    Write-Log "Time Sync Repair Complete." "Green"
} catch {
    Write-Log "Error: $($_.Exception.Message)" "Red"
}
Pause-If-Interactive
