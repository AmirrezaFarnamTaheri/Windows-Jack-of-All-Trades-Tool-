. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Auditing Scheduled Tasks"
Get-SystemSummary

try {
    Write-Section "Scanning Tasks"
    Write-Log "Filtering out default Microsoft/Windows tasks..." "Cyan"

    # Advanced filter: Exclude Microsoft/Windows/Intel/NVIDIA/AMD generally
    $tasks = Get-ScheduledTask | Where-Object {
        $_.Author -notmatch "Microsoft" -and
        $_.Author -notmatch "Windows" -and
        $_.TaskPath -notmatch "\\Microsoft\\Windows"
    }

    if ($tasks) {
        $taskData = @()
        foreach ($t in $tasks) {
            $stateHtml = if ($t.State -eq 'Running') { "<span class='status-pass'>Running</span>" }
                         elseif ($t.State -eq 'Disabled') { "<span class='status-warn'>Disabled</span>" }
                         else { $t.State }

            # Highlight suspicious paths
            $pathHtml = $t.TaskPath
            if ($t.TaskPath -eq '\' -or $t.TaskPath -eq '/') { $pathHtml = "<span class='status-fail'>Root (\)</span>" }

            $actions = ($t.Actions | ForEach-Object { $_.Execute + " " + $_.Arguments }) -join "<br>"

            $taskData += [PSCustomObject]@{
                Name = $t.TaskName
                State = $stateHtml
                Path = $pathHtml
                Author = $t.Author
                Action = $actions
                "Next Run" = try { $t.NextRunTime } catch { "N/A" }
            }
        }

        $report = New-Report "Scheduled Task Audit (Third-Party)"
        $report | Add-ReportSection "Tasks Found ($($tasks.Count))" $taskData "Table"

        $outFile = "$env:USERPROFILE\Desktop\TaskAudit_$(Get-Date -Format 'yyyyMMdd_HHmm').html"
        $report | Export-Report-Html $outFile

        Show-Success "Found $($tasks.Count) non-standard tasks. Report saved."
        Invoke-Item $outFile
    } else {
        Show-Success "No obvious third-party tasks found."
    }
} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
