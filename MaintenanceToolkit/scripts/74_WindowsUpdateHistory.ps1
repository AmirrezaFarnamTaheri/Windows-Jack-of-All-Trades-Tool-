. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Windows Update History"
Get-SystemSummary
Write-Section "Fetching History"

try {
    Write-Log "Querying Windows Update History (COM Object)..." "Cyan"

    $session = New-Object -ComObject Microsoft.Update.Session
    $searcher = $session.CreateUpdateSearcher()
    $historyCount = $searcher.GetTotalHistoryCount()

    if ($historyCount -gt 0) {
        $report = New-Report "Windows Update History"

        $history = $searcher.QueryHistory(0, $historyCount)
        $reportData = @()

        foreach ($entry in $history) {
            $status = switch ($entry.ResultCode) {
                2 { "Success" }
                3 { "Partial" }
                4 { "Failed" }
                5 { "Aborted" }
                default { "Unknown" }
            }

            # Simple color mapping for HTML status
            $statusHtml = $status
            if ($status -eq "Success") { $statusHtml = "<span class='status-pass'>Success</span>" }
            elseif ($status -eq "Failed") { $statusHtml = "<span class='status-fail'>Failed</span>" }
            elseif ($status -eq "Aborted") { $statusHtml = "<span class='status-warn'>Aborted</span>" }

            $reportData += [PSCustomObject]@{
                Date = $entry.Date
                Status = $statusHtml
                Title = $entry.Title
                "Support URL" = if ($entry.SupportUrl) { "<a href='$($entry.SupportUrl)'>Link</a>" } else { "" }
            }
        }

        $report | Add-ReportSection "Update History ($historyCount items)" $reportData "Table"

        $outFile = "$env:USERPROFILE\Desktop\UpdateHistory_$(Get-Date -Format 'yyyyMMdd_HHmm').html"
        $report | Export-Report-Html $outFile

        Show-Success "History exported to $outFile"
        Invoke-Item $outFile

    } else {
        Show-Info "No update history found."
    }

} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
