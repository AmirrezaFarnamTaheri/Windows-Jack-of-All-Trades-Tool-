. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Boot Time Analysis"

try {
    # Event ID 100 in Microsoft-Windows-Diagnostics-Performance/Operational
    $log = Get-WinEvent -LogName "Microsoft-Windows-Diagnostics-Performance/Operational" -MaxEvents 1 -FilterXPath "*[System[(EventID=100)]]" -ErrorAction SilentlyContinue

    if ($log) {
        $bootTimeMs = $log.Properties[0].Value
        $bootTimeSec = [math]::Round($bootTimeMs / 1000, 2)
        Write-Log "Last Boot Time: $bootTimeSec seconds" "Cyan"
    } else {
        Write-Log "No boot time performance logs found." "Yellow"
    }
} catch {
    Write-Log "Error: $($_.Exception.Message)" "Red"
}
Pause-If-Interactive
