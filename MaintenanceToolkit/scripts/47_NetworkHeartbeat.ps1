. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Network Heartbeat Monitor"
Write-Log "Pinging 8.8.8.8 every second. Press Ctrl+C to stop." "Cyan"

try {
    while ($true) {
        $t = Get-Date -Format "HH:mm:ss"
        try {
            $ping = Test-Connection -ComputerName 8.8.8.8 -Count 1 -ErrorAction Stop
            Write-Host "[$t] Reply from $($ping.Address): time=$($ping.ResponseTime)ms" -ForegroundColor Green
        } catch {
            Write-Host "[$t] Request timed out." -ForegroundColor Red
        }
        Start-Sleep -Seconds 1
    }
} catch {
    # Exit loop
}
