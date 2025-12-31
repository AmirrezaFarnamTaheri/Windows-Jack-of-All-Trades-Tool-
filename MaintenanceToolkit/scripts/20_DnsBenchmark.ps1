# Check for Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host "Error: This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator." -ForegroundColor Yellow
    if (-not [Console]::IsInputRedirected) { Pause }
    Exit
}
Write-Host "--- Benchmarking DNS Servers ---" -ForegroundColor Cyan
Write-Host "Testing response times (lower is better)..." -ForegroundColor Yellow

$targets = @{
    "Google (8.8.8.8)" = "8.8.8.8";
    "Cloudflare (1.1.1.1)" = "1.1.1.1";
    "OpenDNS (208.67.222.222)" = "208.67.222.222";
    "Quad9 (9.9.9.9)" = "9.9.9.9"
}

foreach ($name in $targets.Keys) {
    $ip = $targets[$name]
    $time = (Measure-Command { Resolve-DnsName -Name google.com -Server $ip -ErrorAction SilentlyContinue }).TotalMilliseconds
    $time = [math]::Round($time, 2)
    Write-Host "$name : $time ms" -ForegroundColor White
}