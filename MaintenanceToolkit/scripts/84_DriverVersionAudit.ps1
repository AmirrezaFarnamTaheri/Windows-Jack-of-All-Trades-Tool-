. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Driver Version Audit"
Get-SystemSummary
Write-Section "Scanning Drivers"

try {
    # Get all drivers using Get-WmiObject or Get-CimInstance (Win32_PnPSignedDriver)
    # This can be slow, so we warn the user.
    Write-Log "Scanning installed drivers... (This may take a moment)" "Cyan"

    $drivers = Get-WmiObject Win32_PnPSignedDriver | Where-Object { $_.DeviceName -ne $null }

    $thirdParty = $drivers | Where-Object { $_.DriverProviderName -notmatch "Microsoft" -and $_.DriverProviderName -notmatch "Windows" }

    Write-Section "Third-Party Drivers"

    if ($thirdParty) {
        $thirdParty | Sort-Object DriverProviderName | ForEach-Object {
            Write-Host "$($_.DeviceName)" -ForegroundColor White
            Write-Host "  Provider: $($_.DriverProviderName)" -ForegroundColor Gray
            Write-Host "  Version:  $($_.DriverVersion)" -ForegroundColor DarkGray
            Write-Host "  Date:     $($_.DriverDate)" -ForegroundColor DarkGray
            Write-Host ""
        }
        Show-Success "Found $($thirdParty.Count) third-party drivers."
    } else {
        Show-Info "No third-party drivers found (or they are signed by Microsoft)."
    }

} catch {
    Show-Error "Error auditing drivers: $($_.Exception.Message)"
}
Pause-If-Interactive
