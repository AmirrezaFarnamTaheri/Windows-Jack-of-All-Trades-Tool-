. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Resynchronizing System Clock"

try {
    Write-Log "Checking w32time service status..."
    $svc = Get-Service w32time
    if ($svc.Status -ne 'Running') {
        Start-Service w32time
        Wait-ServiceStatus -ServiceName "w32time" -Status "Running"
    }

    Write-Log "Registering and re-scanning configuration..."
    w32tm /config /update

    Write-Log "Forcing synchronization (this may take a moment)..."
    # Capture output to detect error strings
    $output = w32tm /resync 2>&1

    if ($output -match "The computer did not resync because no time data was available") {
        throw "No time data available."
    } elseif ($LASTEXITCODE -ne 0) {
        throw "w32tm failed with exit code $LASTEXITCODE"
    }

    Write-Log "Output: $output" "Gray"
    Write-Log "Success: System time is now synced." "Green"

} catch {
    Write-Log "Sync Failed: $($_.Exception.Message)" "Red" "ERROR"
    Write-Log "Attempting aggressive fix (Re-registering w32time)..." "Yellow"

    Stop-Service w32time -Force -ErrorAction SilentlyContinue
    w32tm /unregister
    w32tm /register
    Start-Service w32time
    w32tm /resync
}

Pause-If-Interactive
