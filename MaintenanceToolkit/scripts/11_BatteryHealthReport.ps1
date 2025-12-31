. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Generating Battery Health Report"

$reportPath = "$env:USERPROFILE\Desktop\battery_report.html"

try {
    Write-Log "Analyzing battery usage via powercfg..."
    Start-Process powercfg -ArgumentList "/batteryreport /output `"$reportPath`"" -Wait -NoNewWindow

    if (Test-Path $reportPath) {
        Write-Log "Report generated: $reportPath" "Green"

        if ($IsInteractive) {
             # If run from the GUI via "Interactive" button or raw CLI
             Write-Log "Opening report..." "Yellow"
             Start-Process $reportPath
        } else {
             Write-Log "Note: You can open the file on your Desktop manually." "White"
        }
    } else {
        throw "Report file not created."
    }
} catch {
    Write-Log "Error: $($_.Exception.Message)" "Red"
}

Pause-If-Interactive
