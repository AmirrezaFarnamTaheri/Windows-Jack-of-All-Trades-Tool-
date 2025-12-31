. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Secure Delete File"
$file = Read-Host "Enter path to file to securely delete"

try {
    if (Test-Path $file) {
        Write-Log "Overwriting file with zeros..."
        $size = (Get-Item $file).Length
        if ($size -gt 0) {
            $bytes = New-Object Byte[] $size
            [IO.File]::WriteAllBytes($file, $bytes)
        }

        Write-Log "Deleting file..."
        Remove-Item $file -Force
        Write-Log "File Deleted." "Green"
    } else {
        Write-Log "File not found." "Red"
    }
} catch {
    Write-Log "Error: $($_.Exception.Message)" "Red"
}
Pause-If-Interactive
