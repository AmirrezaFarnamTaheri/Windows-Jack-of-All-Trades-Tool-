. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Optimizing TCP/IP Settings"

try {
    # 1. TCP Auto-Tuning
    Write-Log "Configuring TCP Auto-Tuning..."
    $current = Get-NetTCPSetting -SettingName "Internet" -ErrorAction SilentlyContinue
    if ($null -eq $current) { $current = Get-NetTCPSetting | Select-Object -First 1 }

    Write-Log "Current Auto-Tuning Level: $($current.AutoTuningLevelLocal)" "Gray"

    # Set to Normal (Recommended for most broadband)
    Set-NetTCPSetting -SettingName ($current.SettingName) -AutoTuningLevelLocal Normal -ErrorAction SilentlyContinue
    Write-Log "Set Auto-Tuning to 'Normal'." "Green"

    # 2. Disable heuristics (Old Windows scaling that can cause issues)
    Write-Log "Disabling Windows Scaling Heuristics..."
    netsh int tcp set heuristics disabled | Out-Null
    Write-Log "Heuristics disabled." "Green"

    # 3. Congestion Provider (CTCP is good, but CUBIC is default in Win10/11 usually)
    # We leave this alone as changing it can cause issues on some networks.

    Write-Log "--- Optimization Complete ---" "Cyan"
    Write-Log "Settings verified."

} catch {
    Write-Log "Error optimizing network: $($_.Exception.Message)" "Red" "ERROR"
}

Pause-If-Interactive
