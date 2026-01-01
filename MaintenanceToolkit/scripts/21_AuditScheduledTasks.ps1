. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Auditing Scheduled Tasks"
Get-SystemSummary
Write-Section "Non-Microsoft Tasks"

try {
    Write-Log "Scanning..." "Cyan"
    $tasks = Get-ScheduledTask | Where-Object { $_.Author -notmatch "Microsoft" -and $_.Author -notmatch "Windows" }

    if ($tasks) {
        $tasks | ForEach-Object {
            $color = if ($_.State -eq 'Running') { "Green" } else { "White" }
            Write-Host "Task: " -NoNewline -ForegroundColor Gray
            Write-Host "$($_.TaskName)" -NoNewline -ForegroundColor $color
            Write-Host " | State: $($_.State)" -ForegroundColor Gray
            Write-Host "   Path: $($_.TaskPath)" -ForegroundColor DarkGray
        }
        Write-Section "Summary"
        Show-Success "Found $($tasks.Count) non-Microsoft tasks."
    } else {
        Show-Success "No obvious non-Microsoft tasks found."
    }
} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
