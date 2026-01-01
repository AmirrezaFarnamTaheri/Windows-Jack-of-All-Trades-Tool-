. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Optimizing Network TCP Settings"
Get-SystemSummary
Write-Section "Execution"

try {
    Write-Log "Setting TCP Global Autotuning to Normal..."
    netsh int tcp set global autotuninglevel=normal

    Write-Log "Disabling Windows Scaling Heuristics..."
    netsh int tcp set heuristics disabled

    Show-Success "Network Optimization Applied."
} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
