. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Install Essential Applications"
Get-SystemSummary
Write-Section "Selection"

$apps = @{
    "Google Chrome" = "Google.Chrome"
    "Firefox" = "Mozilla.Firefox"
    "7-Zip" = "7zip.7zip"
    "VLC Media Player" = "VideoLAN.VLC"
    "Notepad++" = "Notepad++.Notepad++"
    "Adobe Reader DC" = "Adobe.Acrobat.Reader.64-bit"
}

if (-not (Test-IsWingetAvailable)) {
    Show-Error "Winget is required."
    Pause-If-Interactive
    Exit
}

foreach ($name in $apps.Keys) {
    $id = $apps[$name]
    do {
        $install = Read-Host "Install $name? (Y/N)"
        if ([string]::IsNullOrWhiteSpace($install)) { $install = "N" }
    } until ($install -match '^[YyNn]$')

    if ($install -match '^[Yy]$') {
        Write-Log "Installing $name..." "Cyan"
        winget install --id $id -e --silent --accept-package-agreements --accept-source-agreements
    }
}

Show-Success "Process Complete."
Pause-If-Interactive
