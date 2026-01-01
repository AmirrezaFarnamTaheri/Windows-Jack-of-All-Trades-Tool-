. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Generating Battery Health Report"
Get-SystemSummary

try {
    Write-Section "Analysis"
    $path = "$env:TEMP\battery-report.html"
    Write-Log "Running powercfg /batteryreport..."
    powercfg /batteryreport /output "$path" /duration 14

    if (Test-Path $path) {
        Show-Success "Report generated at $path"
        # Open with default browser
        Start-Process "$path"
    } else {
        Show-Error "Failed to generate report."
    }
} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
