. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Quick Backup (Documents Mirror)"

$source = [Environment]::GetFolderPath("MyDocuments")
$dest = "D:\Backups\Documents" # Simplified. Real world would ask.
$dest = Read-Host "Enter Backup Destination Path (e.g. E:\Backup)"

try {
    if (-not (Test-Path $dest)) { New-Item $dest -ItemType Directory -Force | Out-Null }

    Write-Log "Mirroring $source to $dest..."
    robocopy "$source" "$dest" /MIR /R:1 /W:1 /NP /MT:8

    Write-Log "Backup Process Finished." "Green"
} catch {
    Write-Log "Error: $($_.Exception.Message)" "Red"
}
Pause-If-Interactive
