. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "DNS Speed Benchmark"
Get-SystemSummary

$targets = @{
    "Google" = "8.8.8.8"
    "Cloudflare" = "1.1.1.1"
    "OpenDNS" = "208.67.222.222"
    "Quad9" = "9.9.9.9"
}

Write-Section "Testing"
Write-Log "Testing DNS Resolution Speed (Average of 5 queries)..." "Cyan"

$results = @()

foreach ($name in $targets.Keys) {
    try {
        $ip = $targets[$name]
        Write-Host "Testing $name ($ip)... " -NoNewline -ForegroundColor Gray

        # Pre-check connectivity
        if (-not (Test-Connection $ip -Count 1 -Quiet -TimeoutSeconds 1 -ErrorAction SilentlyContinue)) {
             Write-Host "Unreachable (Ping Failed)" -ForegroundColor Red
             $results += [PSCustomObject]@{ Provider=$name; IP=$ip; "Avg Response (ms)"="UNREACHABLE" }
             continue
        }

        $totalTime = 0
        $count = 5
        $success = 0

        for ($i=1; $i -le $count; $i++) {
            # Use Resolve-DnsName with exact measurement
            $timer = [System.Diagnostics.Stopwatch]::StartNew()
            try {
                $dnsResult = Resolve-DnsName -Name "google.com" -Server $ip -Type A -ErrorAction Stop
                $timer.Stop()
                if ($dnsResult) {
                    $totalTime += $timer.Elapsed.TotalMilliseconds
                    $success++
                }
            } catch {
                $timer.Stop()
            }
            Start-Sleep -Milliseconds 50
        }

        if ($success -gt 0) {
            $avg = [math]::Round($totalTime / $success, 2)
            Write-Host "$avg ms" -ForegroundColor White
            $results += [PSCustomObject]@{ Provider=$name; IP=$ip; "Avg Response (ms)"=$avg }
        } else {
            Write-Host "Failed" -ForegroundColor Red
            $results += [PSCustomObject]@{ Provider=$name; IP=$ip; "Avg Response (ms)"="TIMEOUT" }
        }
    } catch {
        Write-Log "Error testing $name: $($_.Exception.Message)" "Red"
    }
}

if ($results.Count -gt 0) {
    # Separate valid results for charting
    $validResults = $results | Where-Object { $_."Avg Response (ms)" -is [double] -or $_."Avg Response (ms)" -is [int] } | Sort-Object "Avg Response (ms)"
    $failedResults = $results | Where-Object { $_."Avg Response (ms)" -is [string] }

    $report = New-Report "DNS Speed Benchmark"

    # Recommendation
    $best = $validResults | Select-Object -First 1
    if ($best) {
        $report | Add-ReportSection "Recommendation" "The fastest provider is <strong>$($best.Provider)</strong> ($($best.'Avg Response (ms)') ms)." "RawHtml"
    }

    # Main Chart & Table (Valid Only)
    if ($validResults) {
        $report | Add-ReportSection "Performance Results" $validResults "Table" @{ Label="Provider"; Value="Avg Response (ms)" }
    }

    # Failed Table
    if ($failedResults) {
        $report | Add-ReportSection "Failed / Unreachable" $failedResults "Table"
    }

    $outFile = "$env:USERPROFILE\Desktop\DNSBenchmark_$(Get-Date -Format 'yyyyMMdd_HHmm').html"
    $report | Export-Report-Html $outFile

    Show-Success "Report generated at $outFile"
    Invoke-Item $outFile
} else {
    Show-Error "All DNS benchmarks failed."
}

Pause-If-Interactive
