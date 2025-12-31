. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Starting Windows System Repair"
Write-Log "This process may take 15-30 minutes. Do not close this window." "Yellow"

try {
    # 1. Check Image Health
    Write-Log "Step 1: Checking System Image Health (DISM)..."

    # We capture output to prevent spamming the console too much, but stream it if possible.
    # For robust scripting, we just run it.
    Start-Process -FilePath "dism.exe" -ArgumentList "/Online /Cleanup-Image /ScanHealth" -Wait -NoNewWindow

    if ($LASTEXITCODE -eq 0) {
        Write-Log "Image Check Passed." "Green"
    } else {
        Write-Log "Image Corruption Found or Check Failed. Attempting Repair..." "Red" "WARN"
        Start-Process -FilePath "dism.exe" -ArgumentList "/Online /Cleanup-Image /RestoreHealth" -Wait -NoNewWindow
    }

    # 2. System File Checker
    Write-Log "Step 2: Scanning System Files (SFC)..."
    Start-Process -FilePath "sfc.exe" -ArgumentList "/scannow" -Wait -NoNewWindow

    Write-Log "--- System Repair Complete ---" "Green"
    Write-Log "If SFC said 'found corrupt files and successfully repaired them', restart your PC." "Magenta"

} catch {
    Write-Log "Critical Error during System Repair: $($_.Exception.Message)" "Red" "ERROR"
}

Pause-If-Interactive
