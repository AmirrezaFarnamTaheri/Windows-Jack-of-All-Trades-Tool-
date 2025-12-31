. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "DNS Speed Benchmark"

$targets = @{
    "Google" = "8.8.8.8"
    "Cloudflare" = "1.1.1.1"
    "OpenDNS" = "208.67.222.222"
    "Quad9" = "9.9.9.9"
}

Write-Log "Testing DNS Resolution Speed (Average of 5 queries)..." "Cyan"

foreach ($name in $targets.Keys) {
    try {
        $ip = $targets[$name]
        $totalTime = 0
        $count = 5
        $success = 0

        for ($i=1; $i -le $count; $i++) {
            $time = Measure-Command {
                Resolve-DnsName -Name "google.com" -Server $ip -Type A -ErrorAction SilentlyContinue
            }
            if ($time.TotalMilliseconds -gt 0) { # Simple check if it ran
                $totalTime += $time.TotalMilliseconds
                $success++
            }
        }

        if ($success -gt 0) {
            $avg = [math]::Round($totalTime / $success, 2)
            Write-Log "$name ($ip): $avg ms" "White"
        } else {
            Write-Log "$name ($ip): Timeout/Failed" "Red"
        }
    } catch {
        Write-Log "Error testing $name" "Red"
    }
}
Pause-If-Interactive
