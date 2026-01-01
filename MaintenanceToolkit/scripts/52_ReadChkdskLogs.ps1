. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Read CHKDSK Logs"
Get-SystemSummary
Write-Section "Analysis"

try {
    # Chkdsk logs are in Application Event Log, source 'Wininit' (boot scan) or 'Chkdsk'
    $log = Get-EventLog -LogName Application -Source "Wininit", "Chkdsk" -Newest 1 -ErrorAction SilentlyContinue

    if ($log) {
        Write-Log "Latest Check Disk Result ($($log.TimeGenerated)):" "Cyan"
        Write-Host "----------------------------------------" -ForegroundColor Gray
        Write-Host $log.Message -ForegroundColor White
        Write-Host "----------------------------------------" -ForegroundColor Gray
        Show-Success "Log retrieved."
    } else {
        Write-Log "No recent CHKDSK logs found." "Yellow"
    }
} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
