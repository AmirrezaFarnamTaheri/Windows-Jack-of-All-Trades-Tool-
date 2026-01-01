. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Sleep Timer"
Get-SystemSummary
Write-Section "Configuration"

$min = Read-Host "Enter minutes until shutdown"

if ($min -match "^\d+$") {
    $sec = [int]$min * 60
    Write-Log "Scheduling shutdown in $min minutes..." "Cyan"
    Start-Process shutdown -ArgumentList "/s /t $sec"
    Show-Success "Timer set. To cancel, run 'shutdown /a' in command prompt."
} else {
    Show-Error "Invalid input."
}
Pause-If-Interactive
