. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Software Update & Optimization"
Get-SystemSummary

# 1. Winget Upgrade
if (Test-IsWingetAvailable) {
    Write-Section "Winget Updates"
    Write-Log "Checking for application updates..." "Cyan"

    try {
        # Update sources first
        Start-Process winget -ArgumentList "source update" -Wait -NoNewWindow -ErrorAction SilentlyContinue

        # Run Upgrade
        $wingetArgs = "upgrade", "--all", "--include-unknown", "--accept-package-agreements", "--accept-source-agreements"

        Write-Log "Running: winget upgrade --all" "Gray"
        $proc = Start-Process winget -ArgumentList $wingetArgs -Wait -NoNewWindow -PassThru

        if ($proc.ExitCode -eq 0) {
            Show-Success "All compatible apps updated."
        } elseif ($proc.ExitCode -eq 1) {
            # Code 1 often means "no updates found" or generic error
            Show-Info "No updates found or upgrade process completed."
        } else {
            Write-Log "Winget exited with code: $($proc.ExitCode)" "Yellow"
        }
    } catch {
        Show-Error "Winget failed: $($_.Exception.Message)"
    }
} else {
    Write-Log "Winget not found. Skipping updates." "Yellow"
}

# 2. Power Plan
Write-Section "System Optimization"
Write-Log "Optimizing Power Settings..." "Cyan"
try {
    # Check if High Performance exists, otherwise restore defaults
    $plans = powercfg /list
    if ($plans -match "High performance") {
        Write-Log "High Performance plan detected." "Gray"
    } else {
        Write-Log "Restoring default power schemes..." "Yellow"
        Start-Process powercfg -ArgumentList "-restoredefaultschemes" -Wait -NoNewWindow
    }
} catch {
    Write-Log "Power optimization skipped." "Gray"
}

# 3. NGEN (Native Image Generator) - Optimizes .NET apps
Write-Section ".NET Optimization"
$ngen = "$env:WINDIR\Microsoft.NET\Framework64\v4.0.30319\ngen.exe"
if (Test-Path $ngen) {
    Write-Log "Running NGEN Update (This compiles .NET assemblies for speed)..." "Cyan"
    Start-Process $ngen -ArgumentList "update /nologo" -Wait -NoNewWindow
    Show-Success ".NET Optimization Complete."
}

Write-Section "Complete"
Show-Success "Update and Optimization sequence finished."

Pause-If-Interactive
