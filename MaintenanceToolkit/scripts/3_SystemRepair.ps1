. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Starting Windows System Repair"
Write-Log "This process may take 15-30 minutes. Do not close this window." "Yellow"

try {
    # 1. Check Image Health (DISM)
    Write-Log "Step 1: Checking System Image Health..."

    # Check Internet for DISM /Online
    $dismArgs = "/Online /Cleanup-Image /ScanHealth"
    if (-not (Test-IsConnected)) {
        Write-Log "Warning: No Internet Connection detected. DISM may fail to download repair files." "Yellow"
        Write-Log "Attempting offline scan only..." "Gray"
        # DISM /Online means "Current Running OS", not "Internet".
        # But /RestoreHealth needs internet usually. /ScanHealth does not.
    }

    $process = Start-Process -FilePath "dism.exe" -ArgumentList $dismArgs -Wait -NoNewWindow -PassThru

    # Analyze Component Store (Cleanup opportunity)
    Write-Log "Analyzing Component Store..."
    Start-Process -FilePath "dism.exe" -ArgumentList "/Online /Cleanup-Image /AnalyzeComponentStore" -Wait -NoNewWindow

    if ($process.ExitCode -eq 0) {
        Write-Log "DISM ScanHealth Passed. No corruption detected." "Green"
    } else {
        Write-Log "DISM found issues (Exit Code: $($process.ExitCode)). Attempting Repair..." "Magenta"

        # Repair Attempt
        $repairProcess = Start-Process -FilePath "dism.exe" -ArgumentList "/Online /Cleanup-Image /RestoreHealth" -Wait -NoNewWindow -PassThru
        if ($repairProcess.ExitCode -eq 0) {
            Write-Log "DISM RestoreHealth Completed Successfully." "Green"
        } else {
            Write-Log "DISM Repair Failed. You may need to provide a source manually." "Red"
        }
    }

    # 2. System File Checker (SFC)
    Write-Log "Step 2: Scanning System Files (SFC)..."
    $sfcProcess = Start-Process -FilePath "sfc.exe" -ArgumentList "/scannow" -Wait -NoNewWindow -PassThru

    if ($sfcProcess.ExitCode -eq 0) {
        Write-Log "SFC: No integrity violations found." "Green"
    } elseif ($sfcProcess.ExitCode -eq 1) { # Error
        Write-Log "SFC: Could not perform the requested operation." "Red"
    } else {
        Write-Log "SFC completed. Check logs for details." "Cyan"
        Write-Log "If SFC said 'found corrupt files and successfully repaired them', restart your PC." "Magenta"
    }

    Write-Log "--- System Repair Complete ---" "White"

} catch {
    Write-Log "Critical Error during System Repair: $($_.Exception.Message)" "Red" "ERROR"
}

Pause-If-Interactive
