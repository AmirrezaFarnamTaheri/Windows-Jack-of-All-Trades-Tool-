. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "EMERGENCY RESTART"
Write-Log "Rebooting immediately..." "Red"

try {
    shutdown /r /f /t 0
} catch {
    Restart-Computer -Force
}
