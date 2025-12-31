. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Auditing Scheduled Tasks"

try {
    Write-Log "Listing non-Microsoft Scheduled Tasks..." "Cyan"
    $tasks = Get-ScheduledTask | Where-Object { $_.Author -notmatch "Microsoft" -and $_.Author -notmatch "Windows" }

    foreach ($t in $tasks) {
        Write-Log "Task: $($t.TaskName) | State: $($t.State) | Author: $($t.Author)" "White"
    }

    if ($tasks.Count -eq 0) {
        Write-Log "No obvious non-Microsoft tasks found." "Green"
    }
} catch {
    Write-Log "Error: $($_.Exception.Message)" "Red"
}
Pause-If-Interactive
