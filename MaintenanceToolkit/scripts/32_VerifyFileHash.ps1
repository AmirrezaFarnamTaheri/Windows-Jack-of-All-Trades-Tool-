. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Verify File Hash"
Get-SystemSummary
Write-Section "Input"

$file = Read-Host "Enter path to file"

try {
    if (Test-Path $file) {
        Write-Log "Calculating SHA256 Hash..." "Gray"
        $hash = Get-FileHash -Path $file -Algorithm SHA256
        Write-Section "Result"
        Write-Log "SHA256: $($hash.Hash)" "Cyan"
        Show-Success "Hash verification complete."
    } else {
        Show-Error "File not found."
    }
} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
