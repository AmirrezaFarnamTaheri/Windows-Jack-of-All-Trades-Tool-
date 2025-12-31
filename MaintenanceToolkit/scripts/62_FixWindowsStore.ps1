. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Fixing Windows Store"

try {
    Write-Log "Resetting Store Cache (wsreset)..." "Yellow"
    Start-Process wsreset.exe -ArgumentList "-i" -Wait -NoNewWindow

    Write-Log "Re-registering Store AppX Package..."
    Get-AppXPackage -AllUsers -Name Microsoft.WindowsStore |
    ForEach-Object { Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml" -ErrorAction SilentlyContinue }

    Write-Log "Windows Store Repair Complete." "Green"
} catch {
    Write-Log "Error: $($_.Exception.Message)" "Red"
}
Pause-If-Interactive
