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
        $history = $searcher.QueryHistory(0, $historyCount) | Select-Object Date, Title, ResultCode

        # Map ResultCode
        # 2 = Succeeded, 3 = SucceededWithErrors, 4 = Failed, 5 = Aborted

        $history | ForEach-Object {
            $status = switch ($_.ResultCode) {
                2 { "Success" }
                3 { "Partial" }
                4 { "Failed" }
                5 { "Aborted" }
                default { "Unknown" }
            }
            $color = if ($status -eq "Success") { "Green" } elseif ($status -eq "Failed") { "Red" } else { "Yellow" }

            Write-Host "[$($_.Date)] " -NoNewline -ForegroundColor Gray
            Write-Host "$status " -NoNewline -ForegroundColor $color
            Write-Host "- $($_.Title)" -ForegroundColor White
        }

        Show-Success "History retrieved."
    } else {
        Write-Log "No update history found." "Yellow"
    }

} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
