# Check for Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host "Error: This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator." -ForegroundColor Yellow
    if (-not [Console]::IsInputRedirected) { Pause }
    Exit
}
$TaskName = "SundayNightMaintenance"
# Use relative path if possible, but Task Scheduler needs absolute.
# We assume the user runs this setup script from the toolkit folder.
$ScriptPath = "$PSScriptRoot\_WeeklyMaintenance.ps1"

Write-Host "--- Creating Scheduled Task: $TaskName ---" -ForegroundColor Cyan

# Check if script exists
if (-not (Test-Path $ScriptPath)) {
    Write-Host "ERROR: Could not find $ScriptPath" -ForegroundColor Red
    Write-Host "Please ensure you run this script from the MaintenanceToolkit folder." -ForegroundColor Yellow
if (-not [Console]::IsInputRedirected) {
    Pause
}
    Exit
}

# Define Action (Run PowerShell with the worker script)
$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`""

# Define Trigger (Weekly, Sundays at 8pm)
$Trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 8:00PM

# Define Settings (Run only on AC Power, Wake if needed, Run as Admin)
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries:$false -DontStopIfGoingOnBatteries:$false -StartWhenAvailable -RunOnlyIfNetworkAvailable
$Principal = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest

# Register the Task
try {
    Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings -Principal $Principal -Force
    Write-Host "Success! Your PC will now self-clean every Sunday at 8:00 PM." -ForegroundColor Green
    Write-Host "(The laptop must be plugged in for it to run)." -ForegroundColor Yellow
}
catch {
    Write-Host "Error creating task: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Try running this script as Administrator." -ForegroundColor Magenta
}
if (-not [Console]::IsInputRedirected) {
    Pause
}