. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Firewall Rule Audit"
Get-SystemSummary
Write-Section "Scanning"

try {
    $report = New-Report "Firewall Security Audit"

    Write-Log "Analyzing Active Firewall Profiles..." "Cyan"
    $profiles = Get-NetFirewallProfile | Select-Object Name, Enabled, DefaultInboundAction, DefaultOutboundAction
    $report | Add-ReportSection "Active Profiles" $profiles "Table"

    Write-Section "Blocking Rules (Inbound)"
    $rules = Get-NetFirewallRule -Direction Inbound -Action Block -Enabled True
    $rules = $rules | ForEach-Object {
        $pf = Get-NetFirewallPortFilter -AssociatedNetFirewallRule $_ -ErrorAction SilentlyContinue
        [PSCustomObject]@{
            DisplayName = $_.DisplayName
            Profile     = $_.Profile
            Direction   = $_.Direction
            Action      = $_.Action
            LocalPort   = if ($pf) { ($pf.LocalPort -join ",") } else { "" }
        }
    }

    if ($rules) {
        Write-Log "Found $($rules.Count) active blocking rules." "White"
        $report | Add-ReportSection "Active Blocking Rules" $rules "Table"
    } else {
        Write-Log "No active inbound blocking rules found." "Green"
        $report | Add-ReportSection "Active Blocking Rules" "No active blocking rules found." "Text"
    }

    # Risky Rules: Allow All Inbound
    Write-Log "Scanning for risky 'Allow All' rules..." "Cyan"
    $risky = Get-NetFirewallRule -Direction Inbound -Action Allow -Enabled True | Where-Object { $_.Profile -ne 'Domain' } | ForEach-Object {
        $pf = Get-NetFirewallPortFilter -AssociatedNetFirewallRule $_ -ErrorAction SilentlyContinue
        [PSCustomObject]@{
            DisplayName = $_.DisplayName
            Profile     = $_.Profile
            Direction   = $_.Direction
            Action      = $_.Action
            LocalPort   = if ($pf) { ($pf.LocalPort -join ",") } else { "" }
            _IsAllowAll = (-not $pf) -or ($pf.LocalPort -contains "Any") -or ([string]::IsNullOrWhiteSpace(($pf.LocalPort -join "")))
        }
    } | Where-Object { $_._IsAllowAll } | Select-Object DisplayName, Profile, Direction, Action, LocalPort

    if ($risky) {
        Write-Log "Found $($risky.Count) potentially risky rules (Allow All)." "Yellow"
        $report | Add-ReportSection "Risky Rules (Allow All Inbound)" $risky "Table"
    } else {
        $report | Add-ReportSection "Risky Rules" "No risky 'Allow All' inbound rules found." "Text"
    }

    $outFile = "$env:USERPROFILE\Desktop\FirewallAudit_$(Get-Date -Format 'yyyyMMdd_HHmm').html"
    $report | Export-Report-Html $outFile
    Show-Success "Report saved to $outFile"
    Invoke-Item $outFile

} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
