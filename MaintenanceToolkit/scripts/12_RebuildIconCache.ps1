. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Rebuilding Icon Cache"
Get-SystemSummary
Write-Section "Execution"

try {
    Write-Log "Closing Explorer..." "Yellow"
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2

    $localAppData = "$env:LOCALAPPDATA\Microsoft\Windows\Explorer"
    Write-Log "Deleting Icon Cache files in $localAppData..."
    Get-ChildItem -Path $localAppData -Filter "iconcache*" | Remove-Item -Force -ErrorAction SilentlyContinue

    Write-Log "Restarting Explorer..." "Cyan"
    Start-Process explorer
    Show-Success "Icon Cache Rebuilt."
} catch {
    Show-Error "Error: $($_.Exception.Message)"
    # Ensure explorer restarts even on error
    if (-not (Get-Process explorer -ErrorAction SilentlyContinue)) { Start-Process explorer }
}
Pause-If-Interactive
