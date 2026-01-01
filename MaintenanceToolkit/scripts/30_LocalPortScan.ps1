. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Scanning Local TCP Listening Ports"
Get-SystemSummary
Write-Section "Scan Results"

try {
    Write-Log "Scanning Listening Ports..." "Cyan"
    $connections = Get-NetTCPConnection | Where-Object { $_.State -eq 'Listen' }
    $reportData = @()

    foreach ($conn in $connections) {
        $procName = "Unknown"
        $procId = $conn.OwningProcess

        $proc = Get-Process -Id $procId -ErrorAction SilentlyContinue
        if ($proc) {
            $procName = $proc.ProcessName
            # Try to get path if possible (might require higher privs or fail for system procs)
            # $path = $proc.Path
        }

        $reportData += [PSCustomObject]@{
            Port = $conn.LocalPort
            Protocol = "TCP" # Get-NetTCPConnection implies TCP
            PID = $procId
            Process = $procName
            "Local Address" = $conn.LocalAddress
        }
    }

    if ($reportData.Count -gt 0) {
        $sorted = $reportData | Sort-Object Port
        New-Report "Local Port Audit"
        Add-ReportSection "Listening Ports ($($sorted.Count))" $sorted "Table"

        $outFile = "$env:USERPROFILE\Desktop\PortScan_$(Get-Date -Format 'yyyyMMdd_HHmm').html"
        Export-Report-Html $outFile

        Show-Success "Scan finished. Report saved to $outFile"
        Invoke-Item $outFile
    } else {
        Show-Info "No listening ports found (unlikely)."
    }

} catch {
    Show-Error "Error scanning ports: $($_.Exception.Message)"
}
Pause-If-Interactive
