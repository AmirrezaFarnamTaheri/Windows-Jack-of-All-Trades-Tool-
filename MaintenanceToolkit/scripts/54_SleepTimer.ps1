. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Sleep Timer"
$min = Read-Host "Enter minutes until shutdown"

try {
    $sec = [int]$min * 60
    Write-Log "Scheduling shutdown in $min minutes..."
    shutdown /s /t $sec
    Write-Log "Timer Set. To cancel, run 'shutdown /a' in CMD." "Green"
} catch {
    Write-Log "Error: Invalid input." "Red"
}
Pause-If-Interactive
