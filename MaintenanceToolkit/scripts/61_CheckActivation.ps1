. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Check Windows Activation"
Get-SystemSummary
Write-Section "Status"

try {
    $lic = Get-WmiObject SoftwareLicensingProduct | Where-Object { $_.PartialProductKey -and $_.ApplicationId -eq "55c92734-d682-4d71-983e-d6ec3f16059f" } | Select-Object -First 1

    if ($lic) {
        Write-Log "Product Name: $($lic.Name)" "White"
        Write-Log "Status:       $($lic.LicenseStatus)" "White"
        # 1=Licensed, 0=Unlicensed, etc.

        if ($lic.LicenseStatus -eq 1) {
            Show-Success "Windows is permanently activated."
        } else {
            Write-Log "License Status Code: $($lic.LicenseStatus) (Not fully activated)" "Yellow"
        }
    } else {
        Show-Error "Could not retrieve license info."
    }
} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
