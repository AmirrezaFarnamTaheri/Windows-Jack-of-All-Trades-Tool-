. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Software Update & Optimization"

# 1. Winget Upgrade
if (Get-Command winget -ErrorAction SilentlyContinue) {
    Write-Log "Searching for updates via Winget..." "Cyan"

    # We use a custom process call to handle output better or just let it stream.
    # Interactive mode is better for winget to see progress bars.

    $wingetArgs = "upgrade", "--all", "--include-unknown", "--accept-package-agreements", "--accept-source-agreements"

    # Check if there are updates first?
    # winget upgrade (without --all) lists them.

    try {
        Start-Process winget -ArgumentList $wingetArgs -Wait -NoNewWindow
        Write-Log "Update process finished." "Green"
    } catch {
        Write-Log "Winget execution failed." "Red"
    }
} else {
    Write-Log "Winget is not installed. Skipping software updates." "Yellow"
}

# 2. Power Plan
Write-Log "Resetting Power Plan to Defaults (Fixes stuck throttles)..." "Cyan"
Start-Process powercfg -ArgumentList "-restoredefaultschemes" -Wait -NoNewWindow

# 3. Memory Optimization (Empty Standby List - requires external tool usually, but we can do a GC collect for PowerShell itself or similar minor things)
# [System.GC]::Collect() # Only affects this process.

Write-Log "--- Optimization Complete ---" "Green"

Pause-If-Interactive
