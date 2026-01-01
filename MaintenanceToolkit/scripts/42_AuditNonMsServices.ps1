. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Auditing Non-Microsoft Services"
Get-SystemSummary
Write-Section "Scan Results"

try {
    $services = Get-Service | Where-Object { $_.Status -eq 'Running' }
    $count = 0
    foreach ($s in $services) {
        # Check DisplayName or Company via WMI if needed, but simple filter is good start
        if ($s.DisplayName -notmatch "Microsoft" -and $s.DisplayName -notmatch "Windows") {
            Write-Log "Service: $($s.Name) ($($s.DisplayName))" "White"
            $count++
        }
    }

    Write-Section "Summary"
    if ($count -gt 0) {
        Show-Success "Found $count running non-Microsoft services."
    } else {
        Show-Success "No obvious non-Microsoft services running."
    }
} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
