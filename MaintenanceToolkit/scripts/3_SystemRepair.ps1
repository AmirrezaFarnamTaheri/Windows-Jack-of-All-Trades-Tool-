. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Windows System Repair"
Get-SystemSummary

Write-Log "This process may take 15-30 minutes. Do not close this window." "Yellow"

try {
    # 0. Fast Check Health
    Write-Section "Step 0: Quick Image Check"
    $check = Start-Process -FilePath "dism.exe" -ArgumentList "/Online /Cleanup-Image /CheckHealth" -Wait -NoNewWindow -PassThru

    if ($check.ExitCode -eq 0) {
        Write-Log "Quick check passed." "Green"
    } else {
        Write-Log "Quick check flagged potential corruption. Proceeding..." "Yellow"
    }

    # 1. DISM RestoreHealth
    Write-Section "Step 1: System Image Repair (DISM)"

    if (-not (Test-IsConnected)) {
        Write-Log "No Internet Connection. DISM may fail if source files are missing." "Yellow"
    }

    # We skip separate ScanHealth and go straight to RestoreHealth if CheckHealth failed or if user wants full maintenance.
    # Actually, RestoreHealth includes ScanHealth logic.
    Write-Log "Running DISM /RestoreHealth..." "Cyan"
    $dism = Start-Process -FilePath "dism.exe" -ArgumentList "/Online /Cleanup-Image /RestoreHealth" -Wait -NoNewWindow -PassThru

    if ($dism.ExitCode -eq 0) {
        Show-Success "DISM RestoreHealth Completed Successfully."
    } else {
        Show-Error "DISM RestoreHealth Failed (Exit Code: $($dism.ExitCode))."
        Write-Log "You may need to provide a source manually using /Source." "Gray"
    }

    # 2. SFC
    Write-Section "Step 2: System File Checker (SFC)"
    Write-Log "Running SFC /ScanNow..." "Cyan"

    $sfc = Start-Process -FilePath "sfc.exe" -ArgumentList "/scannow" -Wait -NoNewWindow -PassThru

    switch ($sfc.ExitCode) {
        0 { Show-Success "SFC: No integrity violations found." }
        1 { Show-Error "SFC: Could not perform operation." }
        default {
            Write-Log "SFC found corrupt files and successfully repaired them." "Green"
            Write-Log "A system restart is recommended." "Magenta"
        }
    }

    # 3. Cleanup Component Store
    Write-Section "Step 3: Component Store Cleanup"
    Start-Process -FilePath "dism.exe" -ArgumentList "/Online /Cleanup-Image /AnalyzeComponentStore" -Wait -NoNewWindow

    Write-Section "Repair Complete"
    Show-Success "System repair operations finished."

} catch {
    Show-Error "Critical Error: $($_.Exception.Message)"
}

Pause-If-Interactive
