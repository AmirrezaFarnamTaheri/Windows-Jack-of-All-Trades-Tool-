# Check for Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host "Error: This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator." -ForegroundColor Yellow
    if (-not [Console]::IsInputRedirected) { Pause }
    Exit
}
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