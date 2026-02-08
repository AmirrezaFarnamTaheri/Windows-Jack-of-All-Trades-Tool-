. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Auditing Scheduled Tasks"
Get-SystemSummary

try {
    Write-Section "Scanning Tasks"
    Write-Log "Filtering out default Microsoft/Windows tasks..." "Cyan"

    # 1. Standard Third-Party Tasks
    $tasks = Get-ScheduledTask | Where-Object {
        $_.Author -notmatch "Microsoft" -and
        $_.Author -notmatch "Windows" -and
        $_.TaskPath -notmatch "\\Microsoft\\Windows"
    }

    $reportData = @()

    foreach ($t in $tasks) {
        $stateHtml = if ($t.State -eq 'Running') { "<span class='status-pass'>Running</span>" }
                     elseif ($t.State -eq 'Disabled') { "<span class='status-warn'>Disabled</span>" }
                     else { $t.State }

        # Check for root path (Suspicious)
        $pathHtml = $t.TaskPath
        if ($t.TaskPath -eq '\' -or $t.TaskPath -eq '/') { $pathHtml = "<span class='status-fail'>Root (\)</span>" }

        # Check for High Privileges
        $privHtml = "Normal"
        if ($t.Principal.RunLevel -eq "Highest") { $privHtml = "<span class='status-warn'>Highest</span>" }

        $actions = ($t.Actions | ForEach-Object { $_.Execute + " " + $_.Arguments }) -join "<br>"

        $reportData += [PSCustomObject]@{
            Name = $t.TaskName
            State = $stateHtml
            Location = $pathHtml
            Author = $t.Author
            Privilege = $privHtml
            Action = $actions
            User = $t.Principal.UserId
        }
    }

    $report = New-Report "Scheduled Task Audit"

    if ($reportData.Count -gt 0) {
        $report | Add-ReportSection "Third-Party Tasks ($($reportData.Count))" $reportData "Table"
    } else {
        $report | Add-ReportSection "Third-Party Tasks" "No non-Microsoft tasks found." "Text"
    }

    # 2. Suspicious System Tasks (Heuristic)
    # Check for tasks running as SYSTEM but executing files in user-writable dirs (AppData, Temp, Public)
    Write-Log "Analyzing System tasks for path anomalies..." "Cyan"
    $susTasks = Get-ScheduledTask | Where-Object {
        $_.Principal.UserId -match "SYSTEM" -and
        ($_.Actions.Execute -match "AppData" -or $_.Actions.Execute -match "Temp" -or $_.Actions.Execute -match "Public")
    }

    if ($susTasks) {
        $susData = @()
        foreach ($t in $susTasks) {
            $susData += [PSCustomObject]@{
                Name = $t.TaskName
                Action = ($t.Actions.Execute + " " + $t.Actions.Arguments)
                Path = $t.TaskPath
            }
        }
        $report | Add-ReportSection "Suspicious System Tasks (Writable Paths)" $susData "Table"
        Write-Log "Found $($susTasks.Count) suspicious System tasks." "Red"
    }

    $outFile = "$env:USERPROFILE\Desktop\TaskAudit_$(Get-Date -Format 'yyyyMMdd_HHmm').html"
    $report | Export-Report-Html $outFile

    Show-Success "Audit Complete. Report saved."
    Invoke-Item $outFile

} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
