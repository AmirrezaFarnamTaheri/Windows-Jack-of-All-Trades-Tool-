. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Generating Battery Health Report"

try {
    $path = "$env:TEMP\battery-report.html"
    Write-Log "Running powercfg /batteryreport..."
    powercfg /batteryreport /output "$path" /duration 14

    if (Test-Path $path) {
        Write-Log "Report generated at $path" "Green"
        Start-Process "$path"
    } else {
        Write-Log "Failed to generate report." "Red"
    }
} catch {
    Write-Log "Error: $($_.Exception.Message)" "Red"
}
Pause-If-Interactive
