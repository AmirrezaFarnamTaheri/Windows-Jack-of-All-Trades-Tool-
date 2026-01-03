. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Emergency Restart"
Get-SystemSummary
Write-Section "Warning"
Write-Log "This will immediately restart the system. Unsaved work will be lost." "Red"

$c = Read-Host "Type 'OK' to confirm"
if ($c.Trim() -ceq 'OK') {
    Stop-Computer -Force -Restart
} else {
    Write-Log "Cancelled." "Yellow"
}
Pause-If-Interactive
