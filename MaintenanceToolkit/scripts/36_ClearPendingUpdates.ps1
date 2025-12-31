. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Clearing Pending Windows Updates (Boot Loop Fix)"

try {
    $pendingFile = "$env:WINDIR\winsxs\pending.xml"
    if (Test-Path $pendingFile) {
        Write-Log "Found pending.xml. Taking ownership..." "Yellow"
        takeown /f "$pendingFile" /a
        icacls "$pendingFile" /grant Administrators:F

        Write-Log "Renaming pending.xml to pending.old..."
        Rename-Item "$pendingFile" "pending.old" -Force
        Write-Log "Success. Reboot should now proceed normally." "Green"
    } else {
        Write-Log "No pending.xml found. System is likely safe." "Green"
    }
} catch {
    Write-Log "Error: $($_.Exception.Message)" "Red"
}
Pause-If-Interactive
