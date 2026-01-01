. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Setup Auto-Maintenance Schedule"
Get-SystemSummary
Write-Section "Configuration"

$taskName = "MaintenanceToolkit_Weekly"
$scriptPath = "$PSScriptRoot\_WeeklyMaintenance.ps1"

try {
    if (Test-Path $scriptPath) {
        Write-Log "Registering Scheduled Task..." "Cyan"

        $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$scriptPath`""
        $trigger = New-ScheduledTaskTrigger -Weekly -At 3am -DaysOfWeek Sunday
        $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Force | Out-Null

        Show-Success "Task '$taskName' registered to run Weekly on Sundays at 3AM."
    } else {
        Show-Error "Weekly maintenance script not found at $scriptPath"
    }
} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
