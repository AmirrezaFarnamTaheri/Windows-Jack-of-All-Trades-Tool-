# Check for Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host "Error: This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator." -ForegroundColor Yellow
    if (-not [Console]::IsInputRedirected) { Pause }
    Exit
}
Write-Host "--- Scanning Local TCP Listening Ports ---" -ForegroundColor Cyan

$connections = Get-NetTCPConnection | Where-Object { $_.State -eq 'Listen' }
foreach ($conn in $connections) {
    $proc = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
    Write-Host "Port: $($conn.LocalPort) | Service: $($proc.ProcessName)" -ForegroundColor White
}
Write-Host "`nIf you see 'svchost' on suspicious ports, investigate further." -ForegroundColor Yellow