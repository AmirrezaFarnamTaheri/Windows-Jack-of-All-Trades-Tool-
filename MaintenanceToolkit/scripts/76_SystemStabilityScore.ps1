. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "System Stability Score"
Get-SystemSummary
Write-Section "Analysis"

try {
    # Win32_ReliabilityStabilityMetrics returns daily scores
    $metrics = Get-CimInstance Win32_ReliabilityStabilityMetrics -ErrorAction SilentlyContinue | Sort-Object TimeGenerated -Descending | Select-Object -First 30

    if ($metrics) {
        $report = New-Report "System Stability Index"

        $latest = $metrics[0]
        $score = $latest.SystemStabilityIndex

        # Color Logic
        $scoreHtml = $score
        if ($score -ge 8) { $scoreHtml = "<span class='status-pass' style='font-size: 2em'>$score / 10</span>" }
        elseif ($score -ge 5) { $scoreHtml = "<span class='status-warn' style='font-size: 2em'>$score / 10</span>" }
        else { $scoreHtml = "<span class='status-fail' style='font-size: 2em'>$score / 10</span>" }

        $report | Add-ReportSection "Current Stability Score" $scoreHtml "RawHtml"

        $history = @()
        foreach ($m in $metrics) {
            $idx = 0
            if ($null -ne $m.SystemStabilityIndex) {
                $idx = [int][math]::Floor([double]$m.SystemStabilityIndex)
            }
            if ($idx -lt 0) { $idx = 0 }
            if ($idx -gt 10) { $idx = 10 }

             $history += [PSCustomObject]@{
                 Date = $m.TimeGenerated
                 Index = $m.SystemStabilityIndex
                 # Simple visualization bar
                 Graph = "|" * $idx
             }
        }

        $report | Add-ReportSection "30-Day History" $history "Table"

        $outFile = "$env:USERPROFILE\Desktop\StabilityScore_$(Get-Date -Format 'yyyyMMdd_HHmm').html"
        $report | Export-Report-Html $outFile

        Show-Success "Stability report saved to $outFile"
        Invoke-Item $outFile

    } else {
        Write-Log "No stability metrics available (RAC task might be disabled)." "Yellow"
    }

} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
