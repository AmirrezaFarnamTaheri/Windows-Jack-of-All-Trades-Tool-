. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Network Heartbeat Monitor"
Get-SystemSummary
Write-Section "Monitoring"
Write-Log "Pinging 8.8.8.8 every second. Press Ctrl+C to stop." "Cyan"

try {
    while ($true) {
        $t = Get-Date -Format "HH:mm:ss"
        try {
            $TargetHost = "8.8.8.8"
            # Use -TimeoutSeconds to prevent long hangs
            $ping = Test-Connection -ComputerName $TargetHost -Count 1 -TimeoutSeconds 2 -ErrorAction Stop

            $ms = $ping.ResponseTime
            $color = "Green"
            if ($ms -gt 100) { $color = "Yellow" }
            if ($ms -gt 300) { $color = "Red" }

            Write-Log "[$t] Reply from $($ping.Address): time=${ms}ms" $color
        } catch {
            Show-Error "[$t] Request timed out."
        }
        Start-Sleep -Seconds 1
    }
} catch {
    # Exit loop on CTRL+C
    Write-Host ""
}
