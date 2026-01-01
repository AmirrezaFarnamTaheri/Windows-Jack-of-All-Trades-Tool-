. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Backing up Drivers"
Get-SystemSummary

$dest = "$env:USERPROFILE\Desktop\DriversBackup_$(Get-Date -Format 'yyyyMMdd')"

try {
    Write-Section "Preparation"
    if (-not (Test-Path $dest)) {
        New-Item -Path $dest -ItemType Directory | Out-Null
        Write-Log "Created backup directory: $dest" "Gray"
    }

    Write-Section "Exporting Drivers"
    Write-Log "This process may take several minutes..." "Yellow"

    $proc = Start-Process -FilePath "dism.exe" -ArgumentList "/online /export-driver /destination:`"$dest`"" -Wait -NoNewWindow -PassThru

    if ($proc.ExitCode -eq 0) {
        Show-Success "Drivers exported successfully."
        Invoke-Item $dest
    } else {
        Show-Error "DISM Export failed with exit code $($proc.ExitCode)."
    }

} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
