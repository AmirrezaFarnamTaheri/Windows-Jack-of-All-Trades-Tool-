. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Get OEM BIOS Key"
Get-SystemSummary
Write-Section "Execution"

try {
    $key = (Get-WmiObject -Class SoftwareLicensingService).OA3xOriginalProductKey
    if ($key) {
        Show-Success "OEM Key Found: $key"
    } else {
        Write-Log "No OEM Key found in firmware." "Yellow"
    }
} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
