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
        foreach ($e in $events) {
            $user = $e.Properties[5].Value
            $type = if ($e.Properties[8].Value -eq 2) { "Local" } else { "RDP" }
            $ip = if ($e.Properties.Count -gt 18 -and $e.Properties[18].Value) { $e.Properties[18].Value } else { "N/A" }

            Write-Host "[$($e.TimeCreated)] " -NoNewline -ForegroundColor Gray
            Write-Host "$user " -NoNewline -ForegroundColor White
            Write-Host "($type) " -NoNewline -ForegroundColor Cyan
            Write-Host "from $ip" -ForegroundColor DarkGray
        }
        Show-Success "Audit Complete."
    } else {
        Write-Log "No recent interactive login events found." "Yellow"
    }

} catch {
    Show-Error "Error reading Event Log: $($_.Exception.Message)"
}
Pause-If-Interactive
