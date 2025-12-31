. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Backing up Drivers"

$dest = "$env:USERPROFILE\Desktop\DriversBackup_$(Get-Date -Format 'yyyyMMdd')"
try {
    Write-Log "Exporting drivers to $dest (This may take a while)..." "Yellow"
    if (-not (Test-Path $dest)) { New-Item -Path $dest -ItemType Directory | Out-Null }

    dism /online /export-driver /destination:"$dest"

    Write-Log "Drivers Exported Successfully." "Green"
} catch {
    Write-Log "Error: $($_.Exception.Message)" "Red"
}
Pause-If-Interactive
