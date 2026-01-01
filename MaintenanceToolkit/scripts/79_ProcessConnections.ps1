. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Active Process Connections"
Get-SystemSummary
Write-Section "Scanning Network Activity"

try {
    Write-Log "Scanning Established Connections..." "Cyan"
    $connections = Get-NetTCPConnection | Where-Object { $_.State -eq 'Established' }
    $reportData = @()

    if ($connections) {
        foreach ($conn in $connections) {
            $proc = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
            $name = if ($proc) { $proc.ProcessName } else { "Unknown" }

            # Simple DNS resolution attempt (optional, can be slow, so maybe skip or do basic)
            # Keeping it fast: just IP

            $reportData += [PSCustomObject]@{
                Process = $name
                PID = $conn.OwningProcess
                "Remote Address" = $conn.RemoteAddress
                "Remote Port" = $conn.RemotePort
                "Local Port" = $conn.LocalPort
            }
        }

        $sorted = $reportData | Sort-Object Process

        New-Report "Active Process Connections"
        Add-ReportSection "Established Connections ($($sorted.Count))" $sorted "Table"

        $outFile = "$env:USERPROFILE\Desktop\ProcessConnections_$(Get-Date -Format 'yyyyMMdd_HHmm').html"
        Export-Report-Html $outFile

        Show-Success "Scan Complete. Report saved to $outFile"
        Invoke-Item $outFile
    } else {
        Write-Log "No active TCP connections found." "Yellow"
    }

} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
