. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Clearing Event Logs"
Write-Log "This will clear all Windows Event Logs." "Yellow"

try {
    $logs = Get-EventLog -List | Where-Object { $_.Entries.Count -gt 0 }
    foreach ($log in $logs) {
        Write-Log "Clearing $($log.Log)..."
        Clear-EventLog -LogName $log.Log -ErrorAction SilentlyContinue
    }
    Write-Log "All Event Logs Cleared." "Green"
} catch {
    Write-Log "Error: $($_.Exception.Message)" "Red"
}
Pause-If-Interactive
