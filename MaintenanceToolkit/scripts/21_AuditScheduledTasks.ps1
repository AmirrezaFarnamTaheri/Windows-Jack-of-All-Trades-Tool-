. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Auditing Scheduled Tasks"
Get-SystemSummary
Write-Section "Non-Microsoft Tasks"

try {
    Write-Log "Scanning..." "Cyan"
    $tasks = Get-ScheduledTask | Where-Object { $_.Author -notmatch "Microsoft" -and $_.Author -notmatch "Windows" }

    if ($tasks) {
        New-Report "Scheduled Task Audit (Non-Microsoft)"

        $taskData = @()
        foreach ($t in $tasks) {
            $stateHtml = $t.State
            if ($t.State -eq 'Running') { $stateHtml = "<span class='status-pass'>Running</span>" }
            elseif ($t.State -eq 'Disabled') { $stateHtml = "<span class='status-warn'>Disabled</span>" }

            # Simple check for odd paths
            $pathHtml = $t.TaskPath
            if ($t.TaskPath -eq '\' -or $t.TaskPath -eq '/') { $pathHtml = "<strong>Root (\)</strong>" }

            $taskData += [PSCustomObject]@{
                Name = $t.TaskName
                State = $stateHtml
                Path = $pathHtml
                Author = $t.Author
                "Next Run" = try { $t.NextRunTime } catch { "N/A" }
            }
        }

        Add-ReportSection "Suspicious / Third-Party Tasks ($($tasks.Count))" $taskData "Table"

        $outFile = "$env:USERPROFILE\Desktop\TaskAudit_$(Get-Date -Format 'yyyyMMdd_HHmm').html"
        Export-Report-Html $outFile

        Show-Success "Found $($tasks.Count) non-Microsoft tasks. Report saved."
        Invoke-Item $outFile
    } else {
        Show-Success "No obvious non-Microsoft tasks found."
    }
} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
