. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Software Update Manager"
Get-SystemSummary

if (-not (Test-IsWingetAvailable)) {
    Show-Error "Winget is not installed on this system."
    Pause-If-Interactive
    Exit
}

try {
    Write-Section "Checking for Updates"
    Write-Log "Querying installed packages via Winget..." "Cyan"

    # List upgrades
    $upgrades = winget upgrade --include-unknown
    $upgrades | ForEach-Object { Write-Host $_ -ForegroundColor Gray }

    if ($upgrades -match "No installed package found matching input criteria") {
        Show-Success "All apps are up to date!"
    } else {
        Write-Host ""
        Write-Log "Starting Update Process..." "Yellow"
        Write-Log "Note: Some installers may request interaction or require closing apps." "Gray"

        # We run upgrade all.
        # --accept-source-agreements: Auto-accept store agreements
        # --accept-package-agreements: Auto-accept EULAs
        # --include-unknown: Update even if version is 'Unknown'

        $args = "upgrade --all --include-unknown --accept-package-agreements --accept-source-agreements"

        $p = Start-Process winget -ArgumentList $args -Wait -NoNewWindow -PassThru

        if ($p.ExitCode -eq 0) {
            Show-Success "Updates completed successfully."
        } else {
            Show-Warning "Updates completed with warnings or errors (Exit Code: $($p.ExitCode))."
            Write-Log "Common causes: Locked files (running apps), Network issues, or Hash mismatches." "Gray"
        }
    }

} catch {
    Show-Error "Update process failed: $($_.Exception.Message)"
}

Pause-If-Interactive
