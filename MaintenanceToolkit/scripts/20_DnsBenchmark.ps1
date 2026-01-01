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
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            try {
                $result = Resolve-DnsName -Name "google.com" -Server $ip -Type A -ErrorAction Stop
                $sw.Stop()

                if ($result) {
                    $totalTime += $sw.Elapsed.TotalMilliseconds
                    $success++
                }
            } catch {
                $sw.Stop()
            }
        }

        if ($success -gt 0) {
            $avg = [math]::Round($totalTime / $success, 2)
            Write-Host "$avg ms" -ForegroundColor White
            $results += [PSCustomObject]@{ Name=$name; IP=$ip; Time=$avg }
        } else {
            Write-Host "Failed" -ForegroundColor Red
        }
    } catch {
        Write-Log "Error testing $name" "Red"
    }
}

Write-Section "Results"
if ($results.Count -gt 0) {
    $results | Sort-Object Time | Format-Table -AutoSize | Out-String | Write-Host -ForegroundColor Green
    $best = ($results | Sort-Object Time)[0]
    Show-Success "Fastest DNS Provider: $($best.Name) ($($best.Time) ms)"
} else {
    Show-Error "All DNS benchmarks failed."
}

Pause-If-Interactive
