. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Software Update & Optimization"
Get-SystemSummary

# 1. Winget Upgrade
if (Test-IsWingetAvailable) {
    Write-Section "Winget Updates"
    Write-Log "Winget detected. Checking for updates..." "Cyan"

    try {
        # Update sources first
        Write-Log "Updating Winget sources..." "Gray"
        Start-Process winget -ArgumentList "source update" -Wait -NoNewWindow -ErrorAction SilentlyContinue

        Write-Log "Starting upgrade process..."
        $wingetArgs = "upgrade", "--all", "--include-unknown", "--accept-package-agreements", "--accept-source-agreements"

        $proc = Start-Process winget -ArgumentList $wingetArgs -Wait -NoNewWindow -PassThru
        if ($proc.ExitCode -eq 0) {
            Show-Success "All apps are up to date."
        } else {
            Write-Log "Update process finished (Code: $($proc.ExitCode))." "White"
        }
    } catch {
        Show-Error "Winget execution failed: $($_.Exception.Message)"
    }
} else {
    Write-Log "Winget is not installed. Skipping software updates." "Yellow"
}

# 2. Power Plan
Write-Section "System Optimization"
Write-Log "Resetting Power Plan to Defaults (Fixes stuck throttles)..." "Cyan"
try {
    Start-Process powercfg -ArgumentList "-restoredefaultschemes" -Wait -NoNewWindow
    Show-Success "Power Plan reset."
} catch {
    Show-Error "Could not reset power plan."
}

Write-Section "Complete"
Show-Success "Optimization tasks finished."

Pause-If-Interactive
