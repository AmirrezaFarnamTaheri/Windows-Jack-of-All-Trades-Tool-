. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Resetting Network Stack"
Get-SystemSummary
Write-Section "Execution"

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

    Show-Success "Network Reset Complete. A reboot is required."
} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
