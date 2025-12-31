. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Reading Check Disk (chkdsk) Logs"

try {
    Write-Log "Searching Event Log for Wininit events..."
    $log = Get-EventLog -LogName Application -Source Wininit -Newest 1 -ErrorAction SilentlyContinue

    if ($log) {
        Write-Log "Latest Chkdsk Run: $($log.TimeGenerated)" "Cyan"
        Write-Log $log.Message "White"
    } else {
        Write-Log "No Chkdsk logs found in Application Event Log." "Yellow"
    }
} catch {
    Write-Log "Error: $($_.Exception.Message)" "Red"
}
Pause-If-Interactive
