. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Fixing Windows Store"
Get-SystemSummary
Write-Section "Execution"

try {
    Write-Log "Resetting Store Cache (wsreset)..." "Yellow"
    Start-Process wsreset.exe -ArgumentList "-i" -Wait -NoNewWindow

    Write-Log "Re-registering Store AppX Package..."
    Get-AppXPackage -AllUsers -Name Microsoft.WindowsStore |
    ForEach-Object { Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml" -ErrorAction SilentlyContinue }

    Show-Success "Windows Store Repair Complete."
} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
