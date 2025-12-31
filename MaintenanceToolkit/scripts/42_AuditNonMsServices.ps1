. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Auditing Non-Microsoft Services"

try {
    $services = Get-Service | Where-Object { $_.Status -eq 'Running' }
    foreach ($s in $services) {
        # Check DisplayName or Company via WMI if needed, but simple filter is good start
        if ($s.DisplayName -notmatch "Microsoft" -and $s.DisplayName -notmatch "Windows") {
            Write-Log "Service: $($s.Name) ($($s.DisplayName))" "White"
        }
    }
} catch {
    Write-Log "Error: $($_.Exception.Message)" "Red"
}
Pause-If-Interactive
