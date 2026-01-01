. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Resetting Network Stack"

try {
    Write-Log "Flushing DNS..."
    ipconfig /flushdns

    Write-Log "Resetting TCP/IP Stack..."
    netsh int ip reset

    Write-Log "Resetting Winsock..."
    netsh winsock reset

    Write-Log "Release/Renew IP..."
    ipconfig /release
    ipconfig /renew

    Write-Log "Clearing ARP Cache..."
    arp -d *

    Write-Log "Resetting Firewall..."
    netsh advfirewall reset

    Write-Log "Network Reset Complete. A reboot is required." "Green"
} catch {
    Write-Log "Error: $($_.Exception.Message)" "Red"
}
Pause-If-Interactive
