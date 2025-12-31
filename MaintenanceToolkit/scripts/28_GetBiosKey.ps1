. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Get OEM BIOS Key"

try {
    $key = (Get-WmiObject -Class SoftwareLicensingService).OA3xOriginalProductKey
    if ($key) {
        Write-Log "OEM Key Found: $key" "Green"
    } else {
        Write-Log "No OEM Key found in firmware." "Yellow"
    }
} catch {
    Write-Log "Error: $($_.Exception.Message)" "Red"
}
Pause-If-Interactive
