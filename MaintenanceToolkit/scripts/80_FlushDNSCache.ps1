. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Flush DNS & Clear Network Cache"
Get-SystemSummary
Write-Section "Execution"

try {
    Write-Log "Flushing DNS Cache..." "Cyan"
    ipconfig /flushdns

    Write-Log "Registering DNS..." "Cyan"
    ipconfig /registerdns

    Write-Log "Clearing ARP Cache..." "Cyan"
    arp -d *

    Show-Success "Network caches flushed."

} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
