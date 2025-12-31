. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Scanning Local TCP Listening Ports"

$connections = Get-NetTCPConnection | Where-Object { $_.State -eq 'Listen' }
foreach ($conn in $connections) {
    $proc = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
    Write-Host "Port: $($conn.LocalPort) | Service: $($proc.ProcessName)" -ForegroundColor White
}
Write-Host "`nIf you see 'svchost' on suspicious ports, investigate further." -ForegroundColor Yellow