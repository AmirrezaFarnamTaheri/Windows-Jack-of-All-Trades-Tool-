. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Enabling God Mode"
Get-SystemSummary
Write-Section "Execution"

try {
    $desktop = [Environment]::GetFolderPath("Desktop")
    $folderName = "GodMode.{ED7BA470-8E54-465E-825C-99712043E01C}"
    $path = "$desktop\$folderName"

    if (-not (Test-Path $path)) {
        New-Item -Path $path -ItemType Directory | Out-Null
        Show-Success "God Mode folder created on Desktop."
    } else {
        Write-Log "God Mode folder already exists." "Yellow"
    }
} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
