. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Verify File Hash"
$file = Read-Host "Enter path to file"

try {
    if (Test-Path $file) {
        $hash = Get-FileHash -Path $file -Algorithm SHA256
        Write-Log "SHA256: $($hash.Hash)" "Cyan"
    } else {
        Write-Log "File not found." "Red"
    }
} catch {
    Write-Log "Error: $($_.Exception.Message)" "Red"
}
Pause-If-Interactive
