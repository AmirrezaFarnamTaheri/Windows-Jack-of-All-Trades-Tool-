Write-Host "--- Schedule Windows Memory Diagnostic ---" -ForegroundColor Cyan
Write-Host "This will restart your computer and run a deep RAM test." -ForegroundColor Red

$choice = Read-Host "Type 'Y' to Restart and Test now, or 'N' to cancel"

if ($choice -eq 'Y') {
    mdsched.exe
} else {
    Write-Host "Cancelled." -ForegroundColor Yellow
}