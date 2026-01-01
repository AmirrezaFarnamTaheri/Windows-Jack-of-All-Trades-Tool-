. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "System Stability Score"
Get-SystemSummary
Write-Section "Analysis"

try {
    # Win32_ReliabilityStabilityMetrics returns daily scores
    $metrics = Get-CimInstance Win32_ReliabilityStabilityMetrics -ErrorAction SilentlyContinue | Sort-Object TimeGenerated -Descending | Select-Object -First 30

    if ($metrics) {
        $latest = $metrics[0]
        $score = $latest.SystemStabilityIndex

        $color = if ($score -ge 8) { "Green" } elseif ($score -ge 5) { "Yellow" } else { "Red" }

        Write-Host "Current Stability Index: " -NoNewline
        Write-Host "$score / 10" -ForegroundColor $color

        Write-Log "Date: $($latest.TimeGenerated)" "Gray"

        Write-Section "History (Last 30 Days)"
        $metrics | ForEach-Object {
            $bar = "|" * [int]$_.SystemStabilityIndex
            Write-Host "$($_.TimeGenerated.ToString('MM-dd')): " -NoNewline -ForegroundColor Gray
            Write-Host "$($_.SystemStabilityIndex) $bar" -ForegroundColor White
        }
    } else {
        Write-Log "No stability metrics available (RAC task might be disabled)." "Yellow"
    }

} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
