. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Windows Firewall Audit"
Get-SystemSummary
Write-Section "Scanning Firewall Rules"

try {
    # 1. Profile Status
    $profiles = Get-NetFirewallProfile
    $profData = @()
    foreach ($p in $profiles) {
        $status = if ($p.Enabled) { "<span class='status-pass'>Active</span>" } else { "<span class='status-warn'>Disabled</span>" }
        $profData += [PSCustomObject]@{
            Profile = $p.Name
            Enabled = $status
            "Inbound Action" = $p.DefaultInboundAction
            "Outbound Action" = $p.DefaultOutboundAction
        }
    }

    # 2. Risky Rules Analysis
    Write-Log "Analyzing Inbound Rules for risks..." "Cyan"

    # "Risky" = Inbound, Allow, Enabled, Any Protocol OR (TCP/UDP with Any Port)
    $rules = Get-NetFirewallRule -Enabled True -Direction Inbound -Action Allow |
             Get-NetFirewallPortFilter |
             Where-Object {
                $_.Protocol -eq "Any" -or
                ($_.LocalPort -eq "Any" -and ($_.Protocol -eq "TCP" -or $_.Protocol -eq "UDP"))
             }

    $riskData = @()
    foreach ($r in $rules) {
        # Get parent rule details
        $parent = Get-NetFirewallRule -Name $r.InstanceID -ErrorAction SilentlyContinue
        if ($parent) {
            $riskData += [PSCustomObject]@{
                Name = $parent.DisplayName
                Group = $parent.DisplayGroup
                Protocol = $r.Protocol
                Port = $r.LocalPort
                Profile = $parent.Profile
                Program = (Get-NetFirewallApplicationFilter -AssociatedNetFirewallRule $parent -ErrorAction SilentlyContinue).Program
            }
        }
    }

    # Report Generation
    $report = New-Report "Firewall Security Audit"
    $report | Add-ReportSection "Firewall Profiles" $profData "Table"

    if ($riskData.Count -gt 0) {
        Write-Log "Found $($riskData.Count) potentially risky 'Allow All' inbound rules." "Yellow"
        $report | Add-ReportSection "Risky Inbound Rules (Allow All/Any Port)" $riskData "Table"
    } else {
        Show-Success "No obviously risky 'Allow Any' inbound rules found."
        $report | Add-ReportSection "Risky Rules" "No risky rules found." "Text"
    }

    $outFile = "$env:USERPROFILE\Desktop\FirewallAudit_$(Get-Date -Format 'yyyyMMdd_HHmm').html"
    $report | Export-Report-Html $outFile

    Show-Success "Audit Complete. Report saved."
    Invoke-Item $outFile

} catch {
    Show-Error "Error auditing firewall: $($_.Exception.Message)"
}
Pause-If-Interactive
