. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Schedule Windows Memory Diagnostic"
Write-Host "This will restart your computer and run a deep RAM test." -ForegroundColor Red

$choice = Read-Host "Type 'Y' to Restart and Test now, or 'N' to cancel"

if ($choice -eq 'Y') {
    mdsched.exe
} else {
    Write-Host "Cancelled." -ForegroundColor Yellow
}