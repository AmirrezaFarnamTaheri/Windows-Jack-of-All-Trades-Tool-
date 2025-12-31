. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "DNS Speed Benchmark"

$targets = @{
    "Google" = "8.8.8.8"
    "Cloudflare" = "1.1.1.1"
    "OpenDNS" = "208.67.222.222"
    "Quad9" = "9.9.9.9"
}

Write-Log "Pinging DNS Providers (Average of 5 pings)..."

foreach ($name in $targets.Keys) {
    try {
        $ip = $targets[$name]
        $ping = Test-Connection -ComputerName $ip -Count 5 -ErrorAction SilentlyContinue | Measure-Object -Property ResponseTime -Average
        if ($ping) {
            Write-Log "$name ($ip): $([math]::Round($ping.Average)) ms" "White"
        } else {
            Write-Log "$name ($ip): Timeout" "Red"
        }
    } catch {
        Write-Log "Error testing $name" "Red"
    }
}
Pause-If-Interactive
