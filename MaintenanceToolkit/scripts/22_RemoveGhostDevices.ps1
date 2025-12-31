. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Remove Ghost Devices"

Write-Log "This script configures Device Manager to show hidden devices."
Write-Log "It cannot automatically delete them safely."

try {
    Write-Log "Setting environment variable..."
    [Environment]::SetEnvironmentVariable("devmgr_show_nonpresent_devices", "1", "Machine")

    Write-Log "Opening Device Manager..."
    Start-Process devmgmt.msc

    Write-Log "In Device Manager, go to View -> Show hidden devices." "Cyan"
    Write-Log "Delete grayed-out icons manually if needed." "White"
} catch {
    Write-Log "Error: $($_.Exception.Message)" "Red"
}
Pause-If-Interactive
