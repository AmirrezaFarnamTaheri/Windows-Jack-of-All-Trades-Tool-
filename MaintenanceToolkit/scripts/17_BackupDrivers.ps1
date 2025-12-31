. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Backing Up Third-Party Drivers"

$date = Get-Date -Format "yyyy-MM-dd"
$backupRoot = "$env:USERPROFILE\Desktop\DriverBackups"
$backupDir = "$backupRoot\$date"

try {
    if (-not (Test-Path $backupDir)) {
        New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
    }

    Write-Log "Exporting drivers to: $backupDir" "Yellow"
    Write-Log "This may take 2-5 minutes..." "White"

    # Export-WindowsDriver is built-in (DISM wrapper)
    Export-WindowsDriver -Online -Destination $backupDir -ErrorAction Stop

    Write-Log "Drivers exported successfully." "Green"

    # Compress
    Write-Log "Compressing backup to ZIP..."
    $zipFile = "$backupRoot\Drivers_$date.zip"
    Compress-Archive -Path "$backupDir\*" -DestinationPath $zipFile -Force

    # Cleanup raw folder to save space? Optional.
    # Let's keep the zip only.
    Remove-Item -Path $backupDir -Recurse -Force

    Write-Log "Backup saved to: $zipFile" "Green"

} catch {
    Write-Log "Error during driver backup: $($_.Exception.Message)" "Red" "ERROR"
}

Pause-If-Interactive
