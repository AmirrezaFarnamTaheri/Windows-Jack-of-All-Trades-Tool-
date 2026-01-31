. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Deep Disk Cleanup"
Get-SystemSummary

try {
    # 1. Measurement
    $drive = Get-PSDrive C -ErrorAction SilentlyContinue
    $freeBefore = if ($drive) { $drive.Free } else { 0 }

    if ($freeBefore -gt 0) {
        Write-Log "Free Space Before: $(Format-Size $freeBefore)" "Gray"
    }

    # 2. Configuration (StateFlags0001)
    Write-Section "Configuring Cleanup Options"
    Write-Log "Setting registry flags for 'SAGERUN:1'..." "Yellow"

    $cleanmgrKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"
    if (Test-Path $cleanmgrKey) {
        Get-ChildItem $cleanmgrKey | ForEach-Object {
            try {
                # StateFlags0001 = 2 (Pre-selected)
                Set-RegKey -Path $_.PSPath -Name "StateFlags0001" -Value 2 -Type DWord -Force
            } catch {
                Write-Log "Warning: Could not set flag for $($_.PSChildName). Skipping." "DarkGray"
            }
        }
    } else {
        throw "Registry key '$cleanmgrKey' not found. This Windows version may differ."
    }

    # 3. Execution
    Write-Section "Running Cleanup"
    Write-Log "Launching Windows Disk Cleanup (cleanmgr.exe)..." "Cyan"
    Write-Log "This may take several minutes. Please wait." "White"

    $p = Start-Process cleanmgr.exe -ArgumentList "/sagerun:1" -PassThru -NoNewWindow -Wait

    # 4. Result
    $drive = Get-PSDrive C -ErrorAction SilentlyContinue
    $freeAfter = if ($drive) { $drive.Free } else { 0 }

    if ($freeBefore -gt 0 -and $freeAfter -gt 0) {
        $saved = $freeAfter - $freeBefore
        Write-Log "Free Space After:  $(Format-Size $freeAfter)" "Gray"

        if ($saved -gt 0) {
            Show-Success "Cleanup Completed. Recovered: $(Format-Size $saved)"
        } else {
            Show-Info "Cleanup Completed. No significant space reclaimed."
        }
    } else {
        Show-Success "Cleanup Completed."
    }

} catch {
    Show-Error "Deep Cleanup Failed: $($_.Exception.Message)"
}

Pause-If-Interactive
