. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Creating System Restore Point"
Get-SystemSummary

try {
    # 1. Check/Enable System Restore
    Write-Section "Checking System Restore Status"
    if (-not (Assert-SystemRestoreEnabled)) {
        throw "System Restore is disabled and could not be enabled automatically."
    }

    # Check for recent restore points
    $recent = Get-ComputerRestorePoint -ErrorAction SilentlyContinue | Where-Object { $_.CreationTime -gt (Get-Date).AddHours(-24) }
    if ($recent) {
        Write-Log "Notice: ${recent.Count} restore point(s) created in the last 24 hours." "Yellow"
        Write-Log "Windows normally limits this frequency." "Gray"
    }

    # 2. Create Checkpoint
    Write-Section "Creating Restore Point"
    $desc = "MaintenanceToolkit_$(Get-Date -Format 'yyyyMMdd-HHmm')"

    # Registry Hack to allow unlimited restore points (Standard practice for maintenance tools)
    Set-RegKey -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\SystemRestore" -Name "SystemRestorePointCreationFrequency" -Value 0 -Type DWord -Force

    Checkpoint-Computer -Description $desc -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop

    Show-Success "Restore Point '$desc' created successfully."

} catch {
    if ($_.Exception.Message -match "frequency") {
        Write-Log "Notice: Windows limits Restore Points to one every 24 hours." "Yellow"
        Write-Log "The registry bypass attempt may have failed or requires a reboot." "White"
    } else {
        Show-Error "Could not create Restore Point: $($_.Exception.Message)"
        Write-Log "Troubleshooting: Ensure 'System Protection' is turned ON in Windows Settings." "Gray"
    }
}

Pause-If-Interactive
