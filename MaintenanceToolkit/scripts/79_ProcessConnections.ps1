. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Active Process Connections"
Get-SystemSummary
Write-Section "Scanning Network Activity"

try {
    Write-Log "Scanning Established Connections..." "Cyan"

    # 1. Get Connections
    $connections = Get-NetTCPConnection | Where-Object { $_.State -eq 'Established' -and $_.RemoteAddress -ne '127.0.0.1' -and $_.RemoteAddress -ne '::1' }

    if (-not $connections) {
        Write-Log "No active external TCP connections found." "Yellow"
        Pause-If-Interactive
        exit
    }

    # 2. Get Processes (Bulk)
    $processMap = @{}
    Get-Process | ForEach-Object { $processMap[$_.Id] = $_.ProcessName }

    # 3. DNS Cache
    $dnsCache = @{}

    Write-Log "Resolving Hostnames (Process: $($connections.Count) connections)..." "Cyan"

    $reportData = @()
    $i = 0
    foreach ($conn in $connections) {
        $i++
        if ($i % 10 -eq 0) { Write-Progress -Activity "Resolving Connections" -Status "$i / $($connections.Count)" -PercentComplete (($i / $connections.Count) * 100) }

        $pidVal = $conn.OwningProcess
        $name = if ($processMap.ContainsKey($pidVal)) { $processMap[$pidVal] } else { "Unknown ($pidVal)" }

        $remoteIP = $conn.RemoteAddress
        $remoteHost = $remoteIP

        # DNS Lookup with caching
        if ($dnsCache.ContainsKey($remoteIP)) {
            $remoteHost = $dnsCache[$remoteIP]
        } else {
            try {
                # 1 second timeout hack using .NET Async? No, too complex.
                # Just standard look up, usually fast for cached, slow for others.
                # We limit scope by only checking established.
                $entry = [System.Net.Dns]::GetHostEntry($remoteIP)
                $remoteHost = $entry.HostName
                $dnsCache[$remoteIP] = $remoteHost
            } catch {
                $dnsCache[$remoteIP] = $remoteIP # Cache the failure (IP)
            }
        }

        $reportData += [PSCustomObject]@{
            Process = $name
            PID = $pidVal
            "Remote Address" = $remoteIP
            "Remote Host" = $remoteHost
            "Remote Port" = $conn.RemotePort
            "Local Port" = $conn.LocalPort
        }
    }
    Write-Progress -Activity "Resolving Connections" -Completed

    $sorted = $reportData | Sort-Object Process

    $report = New-Report "Active Process Connections"
    $report | Add-ReportSection "Established Connections ($($sorted.Count))" $sorted "Table"

    $outFile = "$env:USERPROFILE\Desktop\ProcessConnections_$(Get-Date -Format 'yyyyMMdd_HHmm').html"
    $report | Export-Report-Html $outFile

    Show-Success "Scan Complete. Report saved to $outFile"
    Invoke-Item $outFile

} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
