. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Benchmarking DNS Servers"

if (-not (Test-IsConnected)) {
    Write-Log "Error: No internet connection detected. Cannot benchmark DNS." "Red"
    Pause-If-Interactive
    Exit
}

Write-Log "Testing response times (Average of 3 queries)..." "Yellow"

$targets = @{
    "Google Primary   " = "8.8.8.8"
    "Google Secondary " = "8.8.4.4"
    "Cloudflare Pri   " = "1.1.1.1"
    "Cloudflare Sec   " = "1.0.0.1"
    "OpenDNS Home     " = "208.67.222.222"
    "Quad9 Secure     " = "9.9.9.9"
    "AdGuard DNS      " = "94.140.14.14"
}

$results = @()

foreach ($key in $targets.Keys) {
    $ip = $targets[$key]
    $totalTime = 0
    $failures = 0
    $attempts = 3

    Write-Host -NoNewline "Testing $key ($ip)... "

    for ($i = 0; $i -lt $attempts; $i++) {
        try {
            $time = (Measure-Command {
                Resolve-DnsName -Name "google.com" -Server $ip -Type A -ErrorAction Stop
            }).TotalMilliseconds
            $totalTime += $time
        } catch {
            $failures++
        }
    }

    if ($failures -eq $attempts) {
        Write-Host "TIMEOUT" -ForegroundColor Red
    } else {
        $avg = [math]::Round($totalTime / ($attempts - $failures), 2)
        Write-Host "$avg ms" -ForegroundColor Green
        $results += [PSCustomObject]@{ Provider = $key; IP = $ip; TimeMs = $avg }
    }
}

Write-Log "`n--- Best Performers ---" "Cyan"
$results | Sort-Object TimeMs | Select-Object -First 3 | Format-Table -AutoSize

Pause-If-Interactive
