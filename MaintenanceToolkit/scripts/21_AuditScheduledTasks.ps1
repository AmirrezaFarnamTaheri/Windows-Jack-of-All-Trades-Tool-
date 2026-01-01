. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Auditing Scheduled Tasks"
Get-SystemSummary
Write-Section "Non-Microsoft Tasks"

try {
    Write-Log "Scanning for Third-Party Tasks..." "Cyan"

    # Filter out common Microsoft paths and authors
    $tasks = Get-ScheduledTask | Where-Object {
        $_.Author -notmatch "Microsoft" -and
        $_.Author -notmatch "Windows" -and
        $_.TaskPath -notmatch "\\Microsoft\\Windows\\"
    }

    if ($tasks) {
        $tasks | Sort-Object TaskName | ForEach-Object {
            $color = if ($_.State -eq 'Running') { "Green" } else { "White" }
            Write-Host "Name:   " -NoNewline -ForegroundColor Gray
            Write-Host "$($_.TaskName)" -ForegroundColor $color
            Write-Host "State:  $($_.State)" -ForegroundColor Gray
            Write-Host "Author: $($_.Author)" -ForegroundColor DarkGray
            Write-Host "Path:   $($_.TaskPath)" -ForegroundColor DarkGray
            Write-Host ""
        }
        Write-Section "Summary"
        Show-Success "Found $($tasks.Count) potential third-party tasks."
    } else {
        Show-Info "No obvious third-party tasks found."
    }
} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
