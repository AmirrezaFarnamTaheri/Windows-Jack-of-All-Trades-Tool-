. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Detailed System Info Export"
Get-SystemSummary
Write-Section "Execution"

$outFile = "$env:USERPROFILE\Desktop\SystemSpec_$(Get-Date -Format 'yyyyMMdd_HHmm').txt"

try {
    Write-Log "Gathering System Information (systeminfo)..." "Cyan"
    systeminfo | Out-File $outFile -Encoding UTF8

    Write-Log "Gathering Computer Info (PowerShell)..." "Cyan"
    Get-ComputerInfo | Format-List * | Out-File $outFile -Append -Encoding UTF8

    Show-Success "System info exported to $outFile"
    Invoke-Item $outFile

} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
