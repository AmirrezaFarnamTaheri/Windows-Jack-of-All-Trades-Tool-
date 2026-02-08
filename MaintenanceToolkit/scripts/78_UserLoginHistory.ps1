. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "User Login History Audit"
Get-SystemSummary
Write-Section "Scanning Security Log (Last 100 Events)"

try {
    # Event 4624 = Successful Logon
    # LogonType 2 = Interactive (Local), 10 = Remote (RDP)

    $events = Get-WinEvent -LogName Security -FilterXPath "*[System[(EventID=4624)]]" -MaxEvents 100 -ErrorAction SilentlyContinue |
              Where-Object { $_.Properties[8].Value -eq 2 -or $_.Properties[8].Value -eq 10 }

    if ($events) {
        $logonData = @()

        foreach ($e in $events) {
            $user = $e.Properties[5].Value
            $type = if ($e.Properties[8].Value -eq 2) { "Local (Interactive)" } else { "Remote (RDP)" }
            $ip = $e.Properties[18].Value
            if ([string]::IsNullOrWhiteSpace($ip) -or $ip -eq "-") { $ip = "Localhost" }

            $logonData += [PSCustomObject]@{
                Time = $e.TimeGenerated
                User = $user
                Type = $type
                SourceIP = $ip
            }

            # Console feedback
            Write-Log "[$($e.TimeGenerated)] $user ($type) from $ip" "Cyan"
        }

        $report = New-Report "User Login History Audit"
        $report | Add-ReportSection "Recent Interactive Logons" $logonData "Table"

        $outFile = "$env:USERPROFILE\Desktop\LoginHistory_$(Get-Date -Format 'yyyyMMdd_HHmm').html"
        $report | Export-Report-Html $outFile

        Show-Success "Found $($logonData.Count) events. Report saved to Desktop."
        Invoke-Item $outFile
    } else {
        Show-Info "No recent interactive login events found."
    }

} catch {
    Show-Error "Error reading Event Log: $($_.Exception.Message)"
}
Pause-If-Interactive
