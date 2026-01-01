. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Scanning Local TCP Listening Ports"
Get-SystemSummary
Write-Section "Scan Results"

try {
    $connections = Get-NetTCPConnection | Where-Object { $_.State -eq 'Listen' }
    foreach ($conn in $connections) {
        $proc = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
        Write-Log "Port: $($conn.LocalPort) | PID: $($conn.OwningProcess) | Process: $($proc.ProcessName)" "White"
    }
    Write-Section "Complete"
    Show-Success "Port scan finished."
} catch {
    Show-Error "Error scanning ports: $($_.Exception.Message)"
}
Pause-If-Interactive
