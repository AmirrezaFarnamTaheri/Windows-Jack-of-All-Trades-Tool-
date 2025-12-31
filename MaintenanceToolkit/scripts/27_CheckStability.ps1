. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "System Stability Check"

try {
    Write-Log "Opening Reliability Monitor..."
    Start-Process "perfmon" -ArgumentList "/rel"
    Write-Log "Reliability Monitor opened in a new window." "Green"
} catch {
    Write-Log "Error: $($_.Exception.Message)" "Red"
}
Pause-If-Interactive
