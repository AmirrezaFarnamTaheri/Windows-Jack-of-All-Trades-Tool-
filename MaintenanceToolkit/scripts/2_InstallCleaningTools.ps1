. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Installing Advanced Cleaning Tools"
Get-SystemSummary

# Check if Winget is installed
if (-not (Test-IsWingetAvailable)) {
    Show-Error "Winget not found. Please install 'App Installer' from the Microsoft Store."
    Write-Log "Visit: https://aka.ms/getwinget" "Cyan"
    if (-not [Console]::IsInputRedirected) { Pause }
    return
}

try {
    Write-Section "Installing Malwarebytes"
    winget install --id Malwarebytes.Malwarebytes -e --silent --accept-package-agreements --accept-source-agreements

    Write-Section "Installing BleachBit"
    winget install --id BleachBit.BleachBit -e --silent --accept-package-agreements --accept-source-agreements

    Write-Section "Installation Complete"
    Show-Success "Tools installed successfully."
    Write-Log "ACTION REQUIRED: Please open 'Malwarebytes' manually and run a scan now." "Magenta"
} catch {
    Show-Error "Error during installation: $($_.Exception.Message)"
}

Pause-If-Interactive
