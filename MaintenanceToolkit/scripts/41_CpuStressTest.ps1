. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "CPU Stress Test (Stability Check)"
Write-Log "Press CTRL+C to stop the test." "Yellow"
Write-Log "If your PC shuts down, you have an overheating problem." "Red"

try {
    $start = Get-Date
    # Run a heavy math loop in a background job to stress CPU
    $job = Start-Job -ScriptBlock {
        $result = 1; while ($true) { $result = $result * 1.0000001 }
    }

    Write-Log "Load started on background thread. Monitor Task Manager." "Green"

    while ($job.State -eq 'Running') {
        $elapsed = New-TimeSpan -Start $start -End (Get-Date)
        Write-Host "Stress Testing: $($elapsed.ToString("mm\:ss")) - Press CTRL+C to Stop" -NoNewline -ForegroundColor Red
        Start-Sleep -Seconds 1
        [Console]::SetCursorPosition(0, [Console]::CursorTop)
    }
} finally {
    Stop-Job $job -ErrorAction SilentlyContinue
    Remove-Job $job -ErrorAction SilentlyContinue
    Write-Host "`nTest Stopped." -ForegroundColor Green
}
Pause-If-Interactive
