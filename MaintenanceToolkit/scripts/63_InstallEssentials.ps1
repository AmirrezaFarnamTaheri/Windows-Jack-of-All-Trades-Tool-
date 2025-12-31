. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Install Essential Software"

if (-not (Test-IsWingetAvailable)) {
    Write-Log "Winget not found." "Red"
    Pause-If-Interactive
    return
}

$apps = @(
    "Google.Chrome",
    "VideoLAN.VLC",
    "7zip.7zip",
    "Notepad++.Notepad++"
)

try {
    foreach ($app in $apps) {
        Write-Log "Installing $app..."
        winget install --id $app -e --silent --accept-package-agreements --accept-source-agreements
    }
    Write-Log "Installation Loop Finished." "Green"
} catch {
    Write-Log "Error: $($_.Exception.Message)" "Red"
}
Pause-If-Interactive
