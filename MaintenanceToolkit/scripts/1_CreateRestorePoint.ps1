. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Creating System Restore Point"

try {
    # 1. Check/Enable System Restore
    Write-Log "Checking System Restore status..."
    if (-not (Assert-SystemRestoreEnabled)) {
        throw "System Restore is disabled and could not be enabled automatically."
    }

    # 2. Create Checkpoint
    Write-Log "Attempting to create Restore Point..."
    $desc = "MaintenanceToolkit_$(Get-Date -Format 'yyyyMMdd-HHmm')"

    # Use Checkpoint-Computer
    # Note: This often fails if run too frequently (24h limit). We can override this via registry hack or just warn.
    # Registry Hack to allow unlimited restore points: HKLM\Software\Microsoft\Windows NT\CurrentVersion\SystemRestore -> SystemRestorePointCreationFrequency = 0

    # Optional: Set frequency to 0 to force creation
    Set-RegKey -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\SystemRestore" -Name "SystemRestorePointCreationFrequency" -Value 0 -Type DWord -Force

    Checkpoint-Computer -Description $desc -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop

    Write-Log "Success: Restore Point '$desc' created." "Green"

} catch {
    if ($_.Exception.Message -match "frequency") {
        Write-Log "Notice: Windows limits Restore Points to one every 24 hours." "Yellow"
        Write-Log "A Restore Point was likely created recently. This is normal." "White"
    } else {
        Write-Log "Error: Could not create Restore Point." "Red" "ERROR"
        Write-Log "Details: $($_.Exception.Message)" "Red"
        Write-Log "Troubleshooting: Ensure 'System Protection' is turned ON in Windows Settings." "White"
    }
}

Pause-If-Interactive
