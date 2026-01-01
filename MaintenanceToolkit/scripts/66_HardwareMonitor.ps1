. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Real-Time Hardware Monitor"
Get-SystemSummary
Write-Section "Instructions"
Write-Log "Press CTRL+C or 'Q' to Exit." "Cyan"

$host.UI.RawUI.WindowTitle = "Hardware Monitor"

try {
    while ($true) {
        if ([Console]::KeyAvailable) {
            $k = [Console]::ReadKey($true)
            if ($k.Key -eq 'Q' -or $k.Key -eq 'Escape') { break }
        }

        # CPU Usage
        $cpu = Get-WmiObject Win32_Processor | Measure-Object -Property LoadPercentage -Average | Select-Object -ExpandProperty Average

        # RAM Usage
        $os = Get-WmiObject Win32_OperatingSystem
        $totalRam = $os.TotalVisibleMemorySize / 1kb
        $freeRam = $os.FreePhysicalMemory / 1kb
        $usedRam = $totalRam - $freeRam
        $ramPercent = ($usedRam / $totalRam) * 100

        # Disk Activity (requires Admin, check C:)
        # Disk usage is harder to get "instant" % for without performance counters which are slow to init.
        # We will show Space instead.
        $disk = Get-PSDrive C

        Clear-Host
        Write-Header "Hardware Monitor"
        Write-Host "`n--- System Status ---" -ForegroundColor Yellow

        # Color Logic
        $cpuColor = if ($cpu -gt 80) { "Red" } elseif ($cpu -gt 50) { "Yellow" } else { "Green" }
        $ramColor = if ($ramPercent -gt 80) { "Red" } elseif ($ramPercent -gt 50) { "Yellow" } else { "Green" }

        Write-Host "CPU Usage:       " -NoNewline
        Write-Host "$cpu %" -ForegroundColor $cpuColor

        Write-Host "RAM Usage:       " -NoNewline
        Write-Host "$([math]::Round($usedRam, 0)) MB / $([math]::Round($totalRam, 0)) MB ($([math]::Round($ramPercent,1))%)" -ForegroundColor $ramColor

        Write-Host "C: Drive Free:   " -NoNewline
        Write-Host "$([math]::Round($disk.Free/1GB, 2)) GB" -ForegroundColor White

        Write-Host "`n[Press Q to Exit]" -ForegroundColor DarkGray

        Start-Sleep -Seconds 1
    }
} finally {
    Write-Host "`nMonitor Stopped."
}
Pause-If-Interactive
