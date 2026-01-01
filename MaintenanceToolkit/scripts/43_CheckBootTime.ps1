. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Boot Time Analysis"
Get-SystemSummary
Write-Section "Analysis"

try {
    # Event ID 100 in Microsoft-Windows-Diagnostics-Performance/Operational
    $log = Get-WinEvent -LogName "Microsoft-Windows-Diagnostics-Performance/Operational" -MaxEvents 1 -FilterXPath "*[System[(EventID=100)]]" -ErrorAction SilentlyContinue

    if ($log) {
        $bootTimeMs = $log.Properties[0].Value
        $bootTimeSec = [math]::Round($bootTimeMs / 1000, 2)
        Write-Log "Last Boot Time: $bootTimeSec seconds" "Cyan"

        if ($bootTimeSec -gt 60) {
             Write-Log "Warning: Boot time is slow (>60s)." "Yellow"
        } else {
             Show-Success "Boot time is healthy."
        }
    } else {
        Write-Log "No boot time performance logs found." "Yellow"
    }
} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
