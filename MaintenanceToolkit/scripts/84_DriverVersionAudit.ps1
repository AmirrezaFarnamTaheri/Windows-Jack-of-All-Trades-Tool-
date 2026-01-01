. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Driver Version Audit"
Get-SystemSummary

try {
    Write-Log "Listing third-party drivers (Get-WindowsDriver)..." "Cyan"

    $drivers = Get-WindowsDriver -Online -All | Where-Object { $_.ProviderName -ne "Microsoft" -and $_.ProviderName -ne "Microsoft Corporation" }

    if ($drivers) {
        New-Report "Third-Party Driver Audit"

        $driverData = @()
        foreach ($d in $drivers) {
            $driverData += [PSCustomObject]@{
                "Driver File" = $d.OriginalFileName
                Provider = $d.ProviderName
                Class = $d.ClassName
                Version = $d.Version
                Date = $d.Date
                INF = $d.OriginalInfName
            }
        }

        # Sort by Provider then Class
        $driverData = $driverData | Sort-Object Provider, Class

        Add-ReportSection "Third-Party Drivers ($($drivers.Count))" $driverData "Table"

        $outFile = "$env:USERPROFILE\Desktop\Drivers_$(Get-Date -Format 'yyyyMMdd_HHmm').html"
        Export-Report-Html $outFile

        Show-Success "Exported list to $outFile"
        Invoke-Item $outFile
    } else {
        Show-Info "No third-party drivers found (or access denied)."
    }
} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
