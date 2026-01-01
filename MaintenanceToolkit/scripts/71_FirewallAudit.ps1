. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Firewall Rule Audit"
Get-SystemSummary
Write-Section "Scanning"

try {
    Write-Log "Active Firewall Profiles:" "Cyan"
    Get-NetFirewallProfile | Format-Table Name, Enabled, DefaultInboundAction, DefaultOutboundAction | Out-String | Write-Host

    Write-Section "Blocking Rules (Inbound)"
    $rules = @(Get-NetFirewallRule -Direction Inbound -Action Block -Enabled True)
    if ($rules.Count -gt 0) {
        Write-Log "Found $($rules.Count) active blocking rules." "White"
    } else {
        Write-Log "No active inbound blocking rules found." "Green"
    }

} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
