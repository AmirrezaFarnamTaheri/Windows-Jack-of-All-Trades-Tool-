. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Clearing Clipboard"
Get-SystemSummary

try {
    Write-Section "Clearing Current Content"

    # Try to clear clipboard using PowerShell cmdlet (Text/FileDrop list)
    try {
        Set-Clipboard $null -ErrorAction Stop
        Show-Success "Current clipboard cleared."
    } catch {
        Write-Log "Failed to clear active clipboard via PowerShell." "Yellow"
    }

    # Attempt to clear history (Windows 10/11)
    Write-Section "Clearing Clipboard History"

    # Check if history service is running
    $svc = Get-Service | Where-Object { $_.Name -like "cbdhsvc*" -and $_.Status -eq 'Running' }

    if ($svc) {
        Write-Log "Clipboard User Service ($($svc.Name)) is running." "Cyan"
        Write-Log "Restarting service to flush history..." "Yellow"

        try {
            Stop-Service -Name $svc.Name -Force -ErrorAction Stop
            Start-Service -Name $svc.Name -ErrorAction Stop
            Show-Success "Clipboard History flushed (Service Restarted)."
        } catch {
            Show-Error "Failed to restart service: $($_.Exception.Message)"
        }
    } else {
        Write-Log "Clipboard history service not active or found. History likely already empty or disabled." "Gray"
    }

} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
