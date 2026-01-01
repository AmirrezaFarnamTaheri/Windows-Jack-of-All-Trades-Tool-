. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Clearing Event Logs"
Get-SystemSummary
Write-Log "This will clear all Windows Event Logs." "Yellow"

try {
    Write-Section "Clearing Logs"
    $logs = Get-EventLog -List | Where-Object { $_.Entries.Count -gt 0 }
    foreach ($log in $logs) {
        Write-Log "Clearing $($log.Log)..."
        Clear-EventLog -LogName $log.Log -ErrorAction SilentlyContinue
    }
    Show-Success "All Event Logs Cleared."
} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
