. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Remove Ghost Devices"
Get-SystemSummary
Write-Section "Instructions"

Write-Log "This script enables 'Show Hidden Devices' in Device Manager." "Cyan"
Write-Log "You must manually delete grayed-out icons." "Yellow"

try {
    Write-Log "Setting environment variable..."
    [Environment]::SetEnvironmentVariable("devmgr_show_nonpresent_devices", "1", "Machine")

    Write-Log "Opening Device Manager..."
    Start-Process devmgmt.msc

    Write-Section "Next Steps"
    Write-Log "1. In Device Manager, go to 'View' -> 'Show hidden devices'." "White"
    Write-Log "2. Look for grayed-out icons (Ghost Devices)." "White"
    Write-Log "3. Right-click and Uninstall them if they are no longer needed." "White"

    Show-Success "Device Manager configured."

} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
