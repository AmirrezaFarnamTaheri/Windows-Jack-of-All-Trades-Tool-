. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
$TaskName = "SundayNightMaintenance"
# Use absolute path for Task Scheduler
$ScriptPath = "$PSScriptRoot\_WeeklyMaintenance.ps1"

Write-Header "Setup Weekly Auto-Maintenance"

# Check if script exists
if (-not (Test-Path $ScriptPath)) {
    Write-Log "ERROR: Could not find $ScriptPath" "Red"
    Write-Log "Please ensure you run this script from the MaintenanceToolkit folder." "Yellow"
    if (-not [Console]::IsInputRedirected) { Pause }
    Exit
}

# Define Action
$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`""

# Define Trigger (Weekly, Sundays at 8pm)
$Trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 8:00PM

# Define Settings
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries:$false -DontStopIfGoingOnBatteries:$false -StartWhenAvailable -RunOnlyIfNetworkAvailable
$Principal = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest

# Register the Task
try {
    Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings -Principal $Principal -Force
    Write-Log "Success! Your PC will now self-clean every Sunday at 8:00 PM." "Green"
    Write-Log "(The laptop must be plugged in for it to run)." "Yellow"
}
catch {
    Write-Log "Error creating task: $($_.Exception.Message)" "Red"
}
Pause-If-Interactive
