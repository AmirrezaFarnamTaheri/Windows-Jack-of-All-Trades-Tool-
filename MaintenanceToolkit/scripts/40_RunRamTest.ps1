. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Schedule Windows Memory Diagnostic"
Write-Log "This will restart your computer and run a deep RAM test." "Red"

$choice = Read-Host "Type 'Y' to Restart and Test now, or 'N' to cancel"

if ($choice -eq 'Y') {
    Write-Log "Scheduling Restart..."
    try {
        mdsched.exe
        # mdsched usually prompts UI, but if we want to force it, standard usage is interactive.
        # "mdsched.exe" launches the UI.
    } catch {
        Write-Log "Error launching Memory Diagnostic." "Red"
    }
} else {
    Write-Log "Cancelled." "Yellow"
}
Pause-If-Interactive
