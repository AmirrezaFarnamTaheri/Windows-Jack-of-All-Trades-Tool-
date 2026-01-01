. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Restore Point Manager"
Get-SystemSummary
Write-Section "Existing Restore Points"

try {
    if (Assert-SystemRestoreEnabled) {
        $points = Get-ComputerRestorePoint

        if ($points) {
            $points | Sort-Object CreationTime -Descending | Format-Table CreationTime, Description, EventType, SequenceNumber -AutoSize | Out-String | Write-Host -ForegroundColor White
        } else {
            Show-Info "No restore points found."
        }

        Write-Section "Actions"
        $choice = Read-Host "Create new Restore Point? (Y/N)"
        if ($choice -eq 'Y') {
            $desc = Read-Host "Enter description (default: Maintenance)"
            if ([string]::IsNullOrWhiteSpace($desc)) { $desc = "Maintenance" }

            Write-Log "Creating '$desc'..." "Cyan"
            Checkpoint-Computer -Description $desc -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
            Show-Success "Restore Point created."
        }
    } else {
        Show-Error "System Restore is disabled."
    }

} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
