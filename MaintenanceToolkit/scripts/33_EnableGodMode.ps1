. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Enabling God Mode"

try {
    $desktop = [Environment]::GetFolderPath("Desktop")
    $folderName = "GodMode.{ED7BA470-8E54-465E-825C-99712043E01C}"
    $path = "$desktop\$folderName"

    if (-not (Test-Path $path)) {
        New-Item -Path $path -ItemType Directory | Out-Null
        Write-Log "God Mode folder created on Desktop." "Green"
    } else {
        Write-Log "God Mode folder already exists." "Yellow"
    }
} catch {
    Write-Log "Error: $($_.Exception.Message)" "Red"
}
Pause-If-Interactive
