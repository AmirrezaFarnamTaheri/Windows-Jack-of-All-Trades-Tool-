. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Creating System Restore Point"

try {
    # 1. Check if System Restore is enabled
    $sysRestore = Get-ComputerRestorePoint -ErrorAction SilentlyContinue
    # Actually, Get-ComputerRestorePoint lists points. Enable-ComputerRestore is the cmdlet.
    # To check status: Get-ComputerRestorePoint doesn't show status efficiently.
    # We just try to enable it for C: drive to be safe.

    Write-Log "Ensuring System Restore is enabled for C: drive..."
    Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue

    # 2. Create Checkpoint
    Write-Log "Attempting to create Restore Point..."
    $desc = "MaintenanceToolkit_$(Get-Date -Format 'yyyyMMdd')"

    Checkpoint-Computer -Description $desc -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop

    Write-Log "Success: Restore Point '$desc' created." "Green"

} catch {
    if ($_.Exception.Message -match "frequency") {
        Write-Log "Notice: Windows limits Restore Points to one every 24 hours." "Yellow"
        Write-Log "A Restore Point was likely created recently." "Yellow"
    } else {
        Write-Log "Error: Could not create Restore Point." "Red" "ERROR"
        Write-Log "Details: $($_.Exception.Message)" "Red"
        Write-Log "Troubleshooting: Ensure 'System Protection' is turned ON in Windows Settings." "White"
    }
}

Pause-If-Interactive
