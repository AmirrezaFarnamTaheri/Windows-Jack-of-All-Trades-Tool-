. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Driver Version Audit"
Get-SystemSummary

try {
    Write-Log "Listing third-party drivers (Get-WindowsDriver)..." "Cyan"

    $drivers = Get-WindowsDriver -Online -All | Where-Object { $_.ProviderName -ne "Microsoft" -and $_.ProviderName -ne "Microsoft Corporation" }

    if ($drivers) {
        Write-Section "Third-Party Drivers"
        foreach ($d in $drivers) {
            Write-Log "Driver: $($d.OriginalFileName)" "White"
            Write-Log "  Provider: $($d.ProviderName)" "Gray"
            Write-Log "  Version: $($d.Version)" "Cyan"
            Write-Log "  Date: $($d.Date)" "Gray"
            Write-Diagnostic "  Class: $($d.ClassName) | Inf: $($d.OriginalInfName)"
            Write-Log "-----------------" "DarkGray"
        }

        $outFile = "$env:USERPROFILE\Desktop\Drivers_$(Get-Date -Format 'yyyyMMdd').txt"
        $drivers | Format-Table -AutoSize | Out-File $outFile
        Show-Success "Exported list to $outFile"
    } else {
        Show-Info "No third-party drivers found (or access denied)."
    }
} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
