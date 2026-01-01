. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Flush DNS & Clear Network Cache"
Get-SystemSummary
Write-Section "Execution"

try {
    Write-Log "Flushing DNS Cache..." "Cyan"
    & ipconfig /flushdns | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "ipconfig /flushdns failed with exit code $LASTEXITCODE" }

    Write-Log "Registering DNS..." "Cyan"
    & ipconfig /registerdns | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "ipconfig /registerdns failed with exit code $LASTEXITCODE" }

    Write-Log "Clearing ARP Cache..." "Cyan"
    & arp -d '*' | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "arp cache clear failed with exit code $LASTEXITCODE" }

    Show-Success "Network caches flushed."

} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
