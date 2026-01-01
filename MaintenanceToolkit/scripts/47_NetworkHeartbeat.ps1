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
            $ping = Test-Connection -ComputerName $TargetHost -Count 1 -ErrorAction Stop
            Write-Log "[$t] Reply from $($ping.Address): time=$($ping.ResponseTime)ms" "Green"
        } catch {
            Show-Error "[$t] Request timed out."
        }
        Start-Sleep -Seconds 1
    }
} catch {
    # Exit loop on CTRL+C
    Write-Host ""
}
