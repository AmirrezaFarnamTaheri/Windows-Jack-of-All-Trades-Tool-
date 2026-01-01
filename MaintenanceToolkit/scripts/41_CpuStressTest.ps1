. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "CPU Stress Test (Stability Check)"
Get-SystemSummary
Write-Section "Warning"
Write-Log "This script runs a heavy mathematical loop to stress all CPU cores." "Yellow"
Write-Log "Monitor your CPU temperatures using a separate tool (e.g. HWMonitor)." "Cyan"
Write-Log "If your PC crashes or shuts down, you likely have an overheating or PSU issue." "Red"
Write-Log "Press CTRL+C at any time to STOP the test." "White"

Write-Host "`nPress any key to START the stress test..." -ForegroundColor Green
if (-not [Console]::IsInputRedirected) { $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") }

try {
    $start = Get-Date
    # We want to stress multiple cores.
    $cores = (Get-WmiObject Win32_Processor).NumberOfLogicalProcessors
    if (-not $cores) { $cores = 2 }

    Write-Log "Spawning $cores background jobs to maximize load..." "Green"

    $jobs = @()
    for ($i=0; $i -lt $cores; $i++) {
        $jobs += Start-Job -ScriptBlock {
            $result = 1; while ($true) { $result = [math]::Sqrt($result * 1.0000001) }
        }
    }

    Write-Section "Testing in Progress"

    while ($true) {
        $elapsed = New-TimeSpan -Start $start -End (Get-Date)
        $timeStr = $elapsed.ToString("mm\:ss")

        # Verify jobs are still running
        $running = 0
        foreach ($j in $jobs) { if ($j.State -eq 'Running') { $running++ } }

        Write-Host "`rTime Elapsed: $timeStr | Active Threads: $running/$cores | Press CTRL+C to Stop" -NoNewline -ForegroundColor Cyan

        if ($running -eq 0) {
            Write-Host "`n"
            Show-Error "All stress threads have died unexpectedly."
            break
        }

        Start-Sleep -Seconds 1
    }
} finally {
    Write-Host "`n"
    Write-Section "Stopping Test"
    if ($jobs) {
        Stop-Job $jobs -ErrorAction SilentlyContinue
        Remove-Job $jobs -ErrorAction SilentlyContinue
    }
    Show-Success "Stress test stopped. CPU load returning to normal."
}
Pause-If-Interactive
