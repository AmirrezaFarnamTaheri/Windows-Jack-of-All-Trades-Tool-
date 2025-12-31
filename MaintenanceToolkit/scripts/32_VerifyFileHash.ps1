$file = Read-Host "Drag and drop the file here to verify"
$file = $file -replace '"', ''

if (Test-Path $file) {
    Write-Host "Calculating SHA256 Hash..." -ForegroundColor Yellow
    $hash = Get-FileHash -Path $file -Algorithm SHA256
    Write-Host "Hash: $($hash.Hash)" -ForegroundColor Green
    Set-Clipboard -Value $hash.Hash
    Write-Host "(Hash copied to clipboard)" -ForegroundColor DarkGray
} else {
    Write-Host "File not found." -ForegroundColor Red
}