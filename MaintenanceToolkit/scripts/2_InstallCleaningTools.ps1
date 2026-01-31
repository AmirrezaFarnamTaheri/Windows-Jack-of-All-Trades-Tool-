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
    Write-Section "Installing Cleaning Tools"

    # Use the new robust wrapper from Common.ps1
    Install-WingetApp -Id "Malwarebytes.Malwarebytes" -Name "Malwarebytes"
    Install-WingetApp -Id "BleachBit.BleachBit" -Name "BleachBit"

    Write-Section "Installation Complete"
    Show-Success "Tools check completed."
    Write-Log "Recommendation: Open 'Malwarebytes' and run an initial scan." "Magenta"
} catch {
    Show-Error "Installation error: $($_.Exception.Message)"
}

Pause-If-Interactive
