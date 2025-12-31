. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Software Update & Optimization"

# 1. Winget Upgrade
if (Test-IsWingetAvailable) {
    Write-Log "Winget detected. Checking for updates..." "Cyan"

    try {
        # Update sources first
        Write-Log "Updating Winget sources..." "Gray"
        Start-Process winget -ArgumentList "source update" -Wait -NoNewWindow -ErrorAction SilentlyContinue

        Write-Log "Starting upgrade process..."
        $wingetArgs = "upgrade", "--all", "--include-unknown", "--accept-package-agreements", "--accept-source-agreements"

        $proc = Start-Process winget -ArgumentList $wingetArgs -Wait -NoNewWindow -PassThru
        if ($proc.ExitCode -eq 0) {
            Write-Log "All apps are up to date." "Green"
        } else {
            Write-Log "Update process finished (Code: $($proc.ExitCode))." "White"
        }
    } catch {
        Write-Log "Winget execution failed: $($_.Exception.Message)" "Red"
    }
} else {
    Write-Log "Winget is not installed. Skipping software updates." "Yellow"
}

# 2. Power Plan
Write-Log "Resetting Power Plan to Defaults (Fixes stuck throttles)..." "Cyan"
try {
    Start-Process powercfg -ArgumentList "-restoredefaultschemes" -Wait -NoNewWindow
    Write-Log "Power Plan reset." "Green"
} catch {
    Write-Log "Could not reset power plan." "Red"
}

Write-Log "--- Optimization Complete ---" "Green"

Pause-If-Interactive
