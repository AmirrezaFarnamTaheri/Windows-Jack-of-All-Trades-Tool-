. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Starting Windows System Repair"
Get-SystemSummary
Write-Log "This process may take 15-30 minutes. Do not close this window." "Yellow"

try {
    # 0. Fast Check Health
    Write-Section "Step 0: Quick Image Health Check"
    $check = Start-Process -FilePath "dism.exe" -ArgumentList "/Online /Cleanup-Image /CheckHealth" -Wait -NoNewWindow -PassThru
    if ($check.ExitCode -ne 0) {
        Write-Log "Quick check flagged potential corruption. Proceeding to deep scan..." "Yellow"
    } else {
        Write-Log "Quick check passed." "Green"
    }

    # 1. Check Image Health (DISM)
    Write-Section "Step 1: Deep System Image Health (DISM)"

    # Check Internet for DISM /Online
    $dismArgs = "/Online /Cleanup-Image /ScanHealth"
    if (-not (Test-IsConnected)) {
        Write-Log "Warning: No Internet Connection detected. DISM may fail to download repair files." "Yellow"
        Write-Log "Attempting offline scan only..." "Gray"
    }

    $process = Start-Process -FilePath "dism.exe" -ArgumentList $dismArgs -Wait -NoNewWindow -PassThru

    if ($process.ExitCode -eq 0) {
        Show-Success "DISM ScanHealth Passed. No corruption detected."
    } else {
        Write-Log "DISM found issues (Exit Code: $($process.ExitCode)). Attempting Repair..." "Magenta"

        # Repair Attempt
        $repairProcess = Start-Process -FilePath "dism.exe" -ArgumentList "/Online /Cleanup-Image /RestoreHealth" -Wait -NoNewWindow -PassThru
        if ($repairProcess.ExitCode -eq 0) {
            Show-Success "DISM RestoreHealth Completed Successfully."
        } else {
            Show-Error "DISM Repair Failed. You may need to provide a source manually."
        }
    }

    # Analyze Component Store (Cleanup opportunity)
    Write-Log "Analyzing Component Store for cleanup opportunities..." "Gray"
    Start-Process -FilePath "dism.exe" -ArgumentList "/Online /Cleanup-Image /AnalyzeComponentStore" -Wait -NoNewWindow

    # 2. System File Checker (SFC)
    Write-Section "Step 2: Scanning System Files (SFC)"
    $sfcProcess = Start-Process -FilePath "sfc.exe" -ArgumentList "/scannow" -Wait -NoNewWindow -PassThru

    if ($sfcProcess.ExitCode -eq 0) {
        Show-Success "SFC: No integrity violations found."
    } elseif ($sfcProcess.ExitCode -eq 1) { # Error
        Show-Error "SFC: Could not perform the requested operation."
    } else {
        Write-Log "SFC completed. Check logs for details." "Cyan"
        Write-Log "If SFC said 'found corrupt files and successfully repaired them', restart your PC." "Magenta"
    }

    Write-Section "Repair Complete"
    Show-Success "System repair operations finished."

} catch {
    Show-Error "Critical Error during System Repair: $($_.Exception.Message)"
}

Pause-If-Interactive
