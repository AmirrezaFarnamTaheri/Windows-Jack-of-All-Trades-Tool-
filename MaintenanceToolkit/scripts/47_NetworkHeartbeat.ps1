. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Monitoring Network Stability"
Write-Host "Pinging 8.8.8.8... Press CTRL+C to stop." -ForegroundColor Yellow

while ($true) {
    try {
        $ping = Test-Connection -ComputerName 8.8.8.8 -Count 1 -ErrorAction Stop
        $time = $ping.ResponseTime
        $timestamp = Get-Date -Format "HH:mm:ss"

        if ($time -gt 100) {
            Write-Host "[$timestamp] LAG SPIKE: ${time}ms" -ForegroundColor Red
        } else {
            Write-Host "[$timestamp] Stable: ${time}ms" -ForegroundColor DarkGray
        }
    } catch {
        $timestamp = Get-Date -Format "HH:mm:ss"
        Write-Host "[$timestamp] PACKET LOSS / DISCONNECT" -ForegroundColor Red -BackgroundColor White
    }
    Start-Sleep -Seconds 1
}