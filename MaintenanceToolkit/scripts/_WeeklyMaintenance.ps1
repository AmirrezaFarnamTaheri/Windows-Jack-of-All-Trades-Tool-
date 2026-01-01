. "$PSScriptRoot/lib/Common.ps1"
# Non-Interactive Maintenance Script

# Audit Trail
$logPath = "$env:ProgramData\MaintenanceToolkit\Logs"
if (-not (Test-Path $logPath)) { New-Item -Path $logPath -ItemType Directory -Force | Out-Null }
$transcript = "$logPath\WeeklyMaintenance_$(Get-Date -Format 'yyyyMMdd-HHmm').log"
Start-Transcript -Path $transcript -Append

Write-Log "Starting Weekly Maintenance..."

try {
    # 1. Restore Point
    . "$PSScriptRoot\1_CreateRestorePoint.ps1"

    # 2. Disk Cleanup
    # We use Cleanmgr /sagerun:1 (assumes configured)
    Start-Process cleanmgr.exe -ArgumentList "/sagerun:1" -Wait -NoNewWindow
    Write-Log "Disk Cleanup Ran."

    # 3. Updates
    if (Test-IsWingetAvailable) {
        Start-Process winget -ArgumentList "upgrade --all --include-unknown --accept-package-agreements --accept-source-agreements" -Wait -NoNewWindow
        Write-Log "Software Updated."
    }

    # 4. Defender Scan
    Start-Process "MpCmdRun.exe" -ArgumentList "-Scan -ScanType 1" -Wait -NoNewWindow
    Write-Log "Defender Quick Scan Ran."

    Show-Success "Weekly Maintenance Complete."
} catch {
    Show-Error "Weekly Maintenance Failed: $($_.Exception.Message)"
} finally {
    Stop-Transcript
}
