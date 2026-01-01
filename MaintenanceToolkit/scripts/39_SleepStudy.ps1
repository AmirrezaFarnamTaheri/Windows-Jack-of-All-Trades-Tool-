. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Sleep Study (Battery Drain Analysis)"
Get-SystemSummary
Write-Section "Analysis"

try {
    $path = "$env:TEMP\sleep-study.html"
    Write-Log "Running powercfg /sleepstudy..." "Cyan"
    powercfg /sleepstudy /output "$path" /duration 3

    if (Test-Path $path) {
        Show-Success "Report generated at $path"
        Start-Process "$path"
    } else {
        Show-Error "Failed to generate report."
    }
} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
