. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Windows Update History"
Get-SystemSummary

try {
    Write-Section "Querying Update History"
    Write-Log "Connecting to Microsoft.Update.Session..." "Cyan"

    $session = New-Object -ComObject Microsoft.Update.Session
    $searcher = $session.CreateUpdateSearcher()

    # Limit to last 100 updates to keep report manageable
    $limit = 100
    $total = $searcher.GetTotalHistoryCount()
    $count = [math]::Min($limit, $total)

    Write-Log "Retrieving last $count updates (Total: $total)..." "White"

    if ($count -gt 0) {
        $history = $searcher.QueryHistory(0, $count)
        $reportData = @()
        $lastSuccessDate = $null

        foreach ($entry in $history) {
            $status = switch ($entry.ResultCode) {
                2 { "<span class='status-pass'>Success</span>" }
                3 { "<span class='status-warn'>Partial</span>" }
                4 { "<span class='status-fail'>Failed</span>" }
                5 { "<span class='status-warn'>Aborted</span>" }
                default { "Unknown ($($entry.ResultCode))" }
            }

            if ($entry.ResultCode -eq 2 -and $lastSuccessDate -eq $null) {
                $lastSuccessDate = $entry.Date
            }

            $reportData += [PSCustomObject]@{
                Date = $entry.Date
                Result = $status
                Title = $entry.Title
                Description = $entry.Description
            }
        }

        # Calculate Metric
        $daysSince = "Unknown"
        if ($lastSuccessDate) {
            $diff = (Get-Date) - $lastSuccessDate
            $daysSince = "$([math]::Round($diff.TotalDays, 0)) day(s) ago ($($lastSuccessDate.ToShortDateString()))"
        }

        $report = New-Report "Windows Update History (Last $count)"
        $report | Add-ReportSection "Status Summary" "<strong>Last Successful Update:</strong> $daysSince" "RawHtml"
        $report | Add-ReportSection "Recent Updates" $reportData "Table"

        $outFile = "$env:USERPROFILE\Desktop\UpdateHistory_$(Get-Date -Format 'yyyyMMdd_HHmm').html"
        $report | Export-Report-Html $outFile

        Show-Success "Report generated on Desktop."
        Invoke-Item $outFile

    } else {
        Show-Info "No update history available on this machine."
    }

} catch {
    Show-Error "Failed to retrieve history: $($_.Exception.Message)"
}

Pause-If-Interactive
