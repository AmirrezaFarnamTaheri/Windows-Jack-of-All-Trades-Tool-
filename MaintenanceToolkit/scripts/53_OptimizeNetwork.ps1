. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Optimize Network Settings"
Get-SystemSummary

try {
    Write-Section "Current State"
    $before = Get-NetTCPSetting | Select-Object SettingName, AutoTuningLevelLocal | Select-Object -First 1
    Write-Log "Current Autotuning: $($before.AutoTuningLevelLocal)" "Gray"

    Write-Section "Applying Optimizations"

    # 1. TCP Autotuning
    Write-Log "Setting TCP Global Autotuning to 'Normal'..." "Cyan"
    netsh int tcp set global autotuninglevel=normal | Out-Null

    # 2. Heuristics (Legacy scaling that can interfere)
    Write-Log "Disabling Windows Scaling Heuristics..." "Cyan"
    netsh int tcp set heuristics disabled | Out-Null

    # 3. CTCP (Compound TCP) - Optional, good for high latency
    # Some modern Windows versions use 'CUBIC' by default which is fine.
    # We won't force CTCP as it might not be supported on all builds.

    Write-Section "Verification"
    Start-Sleep -Seconds 1
    $after = Get-NetTCPSetting | Select-Object SettingName, AutoTuningLevelLocal | Select-Object -First 1

    if ($after.AutoTuningLevelLocal -eq 'Normal') {
        Show-Success "Optimization Applied Successfully."
    } else {
        Show-Warning "Settings might be managed by Group Policy."
    }

    Write-Section "Latency Test (Google DNS)"
    $target = "8.8.8.8"
    $ping = Test-Connection -ComputerName $target -Count 4 -ErrorAction SilentlyContinue
    if ($ping) {
        $avg = ($ping | Measure-Object -Property ResponseTime -Average).Average
        Write-Log "Average Ping: $avg ms" "Green"
    } else {
        Write-Log "Ping failed. Check connectivity." "Red"
    }

} catch {
    Show-Error "Optimization Failed: $($_.Exception.Message)"
}

Pause-If-Interactive
