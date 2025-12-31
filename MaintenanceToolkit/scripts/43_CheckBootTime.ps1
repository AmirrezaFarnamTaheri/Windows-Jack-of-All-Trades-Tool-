Write-Host "--- Analyzing Last Boot Time ---" -ForegroundColor Cyan

$bootEvent = Get-WinEvent -LogName "Microsoft-Windows-Diagnostics-Performance/Operational" -ErrorAction SilentlyContinue | Where-Object {$_.Id -eq 100} | Select-Object -First 1

if ($bootEvent) {
    [xml]$xml = $bootEvent.ToXml()
    $ms = $xml.Event.UserData.BootPerformanceMonitoring.BootDuration
    $seconds = [math]::Round($ms / 1000, 2)

    Write-Host "Last Boot Duration: $seconds seconds" -ForegroundColor Green

    if ($seconds -gt 60) {
        Write-Host "Status: SLOW (Consider disabling startup apps)" -ForegroundColor Red
    } else {
        Write-Host "Status: HEALTHY" -ForegroundColor Green
    }
} else {
    Write-Host "No boot diagnostics found (Logs might be cleared)." -ForegroundColor Yellow
}