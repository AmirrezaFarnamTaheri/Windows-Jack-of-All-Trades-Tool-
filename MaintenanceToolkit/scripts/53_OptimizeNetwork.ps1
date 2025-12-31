. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Optimizing Network TCP Settings"

try {
    Write-Log "Setting TCP Global Autotuning to Normal..."
    netsh int tcp set global autotuninglevel=normal

    Write-Log "Disabling Windows Scaling Heuristics..."
    netsh int tcp set heuristics disabled

    Write-Log "Network Optimization Applied." "Green"
} catch {
    Write-Log "Error: $($_.Exception.Message)" "Red"
}
Pause-If-Interactive
