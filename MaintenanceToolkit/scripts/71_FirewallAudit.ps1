. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Firewall Rule Audit"
Get-SystemSummary
Write-Section "Scanning"

try {
    New-Report "Firewall Security Audit"

    Write-Log "Analyzing Active Firewall Profiles..." "Cyan"
    $profiles = Get-NetFirewallProfile | Select-Object Name, Enabled, DefaultInboundAction, DefaultOutboundAction
    Add-ReportSection "Active Profiles" $profiles "Table"

    Write-Section "Blocking Rules (Inbound)"
    $rules = Get-NetFirewallRule -Direction Inbound -Action Block -Enabled True | Select-Object DisplayName, Profile, Direction, Action, LocalPort

    if ($rules) {
        Write-Log "Found $($rules.Count) active blocking rules." "White"
        Add-ReportSection "Active Blocking Rules" $rules "Table"
    } else {
        Write-Log "No active inbound blocking rules found." "Green"
        Add-ReportSection "Active Blocking Rules" "No active blocking rules found." "Text"
    }

    # Risky Rules: Allow All Inbound
    Write-Log "Scanning for risky 'Allow All' rules..." "Cyan"
    $risky = Get-NetFirewallRule -Direction Inbound -Action Allow -Enabled True | Where-Object {
        $_.Profile -ne 'Domain' -and ($_.LocalPort -eq 'Any' -or $_.LocalPort -eq $null)
    } | Select-Object DisplayName, Profile, Direction, Action, LocalPort

    if ($risky) {
        Write-Log "Found $($risky.Count) potentially risky rules (Allow All)." "Yellow"
        Add-ReportSection "Risky Rules (Allow All Inbound)" $risky "Table"
    } else {
        Add-ReportSection "Risky Rules" "No risky 'Allow All' inbound rules found." "Text"
    }

    $outFile = "$env:USERPROFILE\Desktop\FirewallAudit_$(Get-Date -Format 'yyyyMMdd_HHmm').html"
    Export-Report-Html $outFile
    Show-Success "Report saved to $outFile"
    Invoke-Item $outFile

} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
