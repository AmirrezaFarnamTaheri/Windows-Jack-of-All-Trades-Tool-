. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "System Stability Check"
Get-SystemSummary

try {
    Write-Section "Reliability Monitor"
    Write-Log "Opening Reliability Monitor..."
    Start-Process "perfmon" -ArgumentList "/rel"
    Write-Log "Reliability Monitor opened in a new window." "Green"

    Write-Section "Recent Critical Errors (Last 24h)"
    $errors = Get-EventLog -LogName System -EntryType Error -After (Get-Date).AddDays(-1) -ErrorAction SilentlyContinue

    if ($errors) {
        $errors | Group-Object Source | Sort-Object Count -Descending | Select-Object Count, Name | Format-Table -AutoSize | Out-String | Write-Host -ForegroundColor White

        Write-Log "Latest 5 Critical Errors:" "Red"
        $errors | Select-Object -First 5 | ForEach-Object {
            Write-Log "[$($_.TimeGenerated)] $($_.Source): $($_.Message)" "Gray"
        }
    } else {
        Show-Success "No critical system errors found in the last 24 hours."
    }

} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
