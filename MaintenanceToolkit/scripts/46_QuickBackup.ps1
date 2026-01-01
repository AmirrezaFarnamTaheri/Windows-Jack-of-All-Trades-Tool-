. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Quick Backup (Documents)"
Get-SystemSummary
Write-Section "Configuration"

$source = [Environment]::GetFolderPath("MyDocuments")
$dest = Read-Host "Enter backup destination path (e.g. D:\Backups)"

if ([string]::IsNullOrWhiteSpace($dest)) {
    Show-Error "Destination is required."
    Pause-If-Interactive
    Exit
}

try {
    Write-Section "Backing Up"
    if (-not (Test-Path $dest)) { New-Item $dest -ItemType Directory -Force | Out-Null }

    $destPath = "$dest\DocsBackup_$(Get-Date -Format 'yyyyMMdd')"
    Write-Log "Source: $source" "White"
    Write-Log "Dest:   $destPath" "White"

    # Robocopy
    # /MIR = Mirror
    # /R:3 /W:5 = Retry 3 times, wait 5 sec
    # /MT:8 = Multi-threaded

    $roboArgs = "`"$source`"", "`"$destPath`"", "/MIR", "/R:3", "/W:5", "/MT:8", "/NP", "/NFL", "/NDL"

    $proc = Start-Process robocopy -ArgumentList $roboArgs -Wait -NoNewWindow -PassThru

    if ($proc.ExitCode -lt 8) {
        Show-Success "Backup completed successfully."
    } else {
        Show-Error "Backup completed with errors (Code: $($proc.ExitCode))."
    }

} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
