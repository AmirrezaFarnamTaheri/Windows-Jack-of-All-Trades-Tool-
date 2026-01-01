. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Schedule Windows Memory Diagnostic"
Get-SystemSummary
Write-Section "Instructions"
Write-Log "This utility will schedule a standard Windows Memory Diagnostic test." "Cyan"
Write-Log "Your computer will restart immediately to begin the test." "Red"
Write-Log "The test may take 15-30 minutes. Results will be shown in Windows Event Viewer." "Gray"

$choice = Read-Host "`nType 'Y' to RESTART and TEST NOW, or 'N' to cancel"

if ($choice -eq 'Y') {
    Write-Section "Scheduling Restart"
    try {
        # mdsched.exe /? shows standard switches, but typically it's interactive.
        # However, launching it with no arguments brings up the standard UI.
        # We can also use bcdedit to force it if needed, but mdsched is safer.

        Start-Process "mdsched.exe" -Wait

        # If user selected "Restart now" in the UI, we won't reach here easily.
        # If they selected "Check on next startup", we confirm.
        Show-Success "Memory Diagnostic tool launched."
    } catch {
        Show-Error "Error launching Memory Diagnostic: $($_.Exception.Message)"
    }
} else {
    Write-Log "Operation Cancelled." "Yellow"
}
Pause-If-Interactive
