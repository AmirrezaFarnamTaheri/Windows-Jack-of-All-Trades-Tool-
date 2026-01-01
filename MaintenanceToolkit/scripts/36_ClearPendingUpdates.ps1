. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Clearing Pending Windows Updates (Boot Loop Fix)"
Get-SystemSummary
Write-Section "Execution"

try {
    $pendingFile = "$env:WINDIR\winsxs\pending.xml"
    if (Test-Path $pendingFile) {
        Write-Log "Found pending.xml. Taking ownership..." "Yellow"
        takeown /f "$pendingFile" /a
        icacls "$pendingFile" /grant Administrators:F

        Write-Log "Renaming pending.xml to pending.old..."
        Rename-Item "$pendingFile" "pending.old" -Force
        Show-Success "Pending updates file disabled. Reboot should now proceed normally."
    } else {
        Show-Success "No pending.xml found. System is likely safe."
    }
} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
