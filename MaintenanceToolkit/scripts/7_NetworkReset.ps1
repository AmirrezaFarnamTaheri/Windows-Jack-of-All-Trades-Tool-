. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Network Stack Reset"
Get-SystemSummary

Assert-Destructive "This action resets all network adapters and settings."

Write-Section "Execution"

try {
    # 1. Flush DNS
    Write-Log "Flushing DNS Resolver Cache..." "Cyan"
    Clear-DnsClientCache -ErrorAction SilentlyContinue

    # 2. Reset Winsock (Modern method via netsh is still standard)
    Write-Log "Resetting Winsock Catalog..." "Cyan"
    Start-Process netsh -ArgumentList "winsock reset" -Wait -NoNewWindow

    # 3. Reset TCP/IP
    Write-Log "Resetting TCP/IP Stack..." "Cyan"
    Start-Process netsh -ArgumentList "int ip reset" -Wait -NoNewWindow

    # 4. Refresh DHCP
    Write-Log "Refreshing DHCP Leases..." "Cyan"
    ipconfig /release | Out-Null
    ipconfig /renew | Out-Null

    # 5. Flush ARP
    Write-Log "Clearing ARP Cache..." "Cyan"
    Start-Process arp -ArgumentList "-d *" -Wait -NoNewWindow

    # 6. Reset Firewall (Optional, user might want to keep rules)
    if ($env:MAINTENANCE_SAFE_MODE -ne '1') {
        # We don't force firewall reset in all cases, maybe ask?
        # For now, we'll skip it or just do it if user is running "Network Reset" they usually mean everything.
        Write-Log "Resetting Windows Firewall..." "Cyan"
        netsh advfirewall reset | Out-Null
    }

    Write-Section "Complete"
    Show-Success "Network settings have been reset."
    Write-Log "A system restart is HIGHLY recommended." "Magenta"

} catch {
    Show-Error "Network Reset Failed: $($_.Exception.Message)"
}

Pause-If-Interactive
