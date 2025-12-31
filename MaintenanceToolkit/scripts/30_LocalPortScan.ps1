. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Scanning Local TCP Listening Ports"

try {
    $connections = Get-NetTCPConnection | Where-Object { $_.State -eq 'Listen' }
    foreach ($conn in $connections) {
        $proc = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
        Write-Log "Port: $($conn.LocalPort) | PID: $($conn.OwningProcess) | Process: $($proc.ProcessName)" "White"
    }
    Write-Log "Scan Complete." "Green"
} catch {
    Write-Log "Error: $($_.Exception.Message)" "Red"
}
Pause-If-Interactive
