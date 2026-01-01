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
        Write-Host "Pinging $name ($ip)... " -NoNewline -ForegroundColor Gray

        $totalTime = 0
        $count = 5
        $success = 0

        for ($i=1; $i -le $count; $i++) {
            $time = Measure-Command {
                Resolve-DnsName -Name "google.com" -Server $ip -Type A -ErrorAction SilentlyContinue
            }
            if ($time.TotalMilliseconds -gt 0) {
                $totalTime += $time.TotalMilliseconds
                $success++
            }
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
        Write-Log "Error testing $name" "Red"
    }
}

if ($results.Count -gt 0) {
    $sorted = $results |
      Sort-Object @{ Expression = {
        if ($_."Avg Response (ms)" -match '^\d') { [double]$_."Avg Response (ms)" }
        else { [double]::MaxValue }
      } }

    $report = New-Report "DNS Speed Benchmark"
    $report | Add-ReportSection "Benchmark Results" $sorted "Table"

    $best = $sorted | Where-Object { $_."Avg Response (ms)" -match '^\d' } | Select-Object -First 1
    $report | Add-ReportSection "Recommendation" "Based on this test, the fastest provider for you is <strong>$($best.Provider)</strong>." "RawHtml"

    $outFile = "$env:USERPROFILE\Desktop\DNSBenchmark_$(Get-Date -Format 'yyyyMMdd_HHmm').html"
    $report | Export-Report-Html $outFile

    Show-Success "Report generated at $outFile"
    Invoke-Item $outFile
} else {
    Show-Error "All DNS benchmarks failed."
}

Pause-If-Interactive
