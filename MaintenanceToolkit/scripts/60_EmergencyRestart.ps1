Write-Host "--- EMERGENCY RESTART ---" -ForegroundColor Red
Write-Host "This will not save open documents."
$confirm = Read-Host "Type 'RESTART' to confirm"

if ($confirm -eq 'RESTART') {
    shutdown /r /f /t 0
}