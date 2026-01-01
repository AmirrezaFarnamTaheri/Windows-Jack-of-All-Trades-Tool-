. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Panic Button"
Get-SystemSummary
Write-Section "Executing Panic Mode"

try {
    Write-Log "Muting Audio..."
    # Placeholder for mute (requires detailed Audio API or nircmd)
    # We can try stop audio service for brute force
    Stop-Service "Audiosrv" -Force -ErrorAction SilentlyContinue

    Write-Log "Clearing Clipboard..."
    Set-Clipboard $null

    Write-Log "Minimizing All Windows..."
    $shell = New-Object -ComObject Shell.Application
    $shell.MinimizeAll()

    Write-Log "Clearing Recent Docs..."
    Remove-Item "$env:APPDATA\Microsoft\Windows\Recent\*" -Force -ErrorAction SilentlyContinue

    Show-Success "Panic measures executed."

    # Restore Audio later manually?
    Write-Log "Note: Audio Service stopped. Use 'Restart Audio' script to fix." "Yellow"

} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
