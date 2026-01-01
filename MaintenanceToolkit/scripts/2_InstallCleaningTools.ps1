. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Installing Advanced Cleaning Tools via Winget"

# Check if Winget is installed
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Log "Winget not found. Attempting to install App Installer..." "Yellow"
    Write-Log "Winget is required for this script. Please install 'App Installer' from the Microsoft Store or update Windows." "Red"
    Write-Log "Visit: https://aka.ms/getwinget" "Cyan"
    if (-not [Console]::IsInputRedirected) { Pause }
    return
}

try {
    # 1. Malwarebytes
    Write-Log "Installing Malwarebytes..."
    winget install --id Malwarebytes.Malwarebytes -e --silent --accept-package-agreements --accept-source-agreements

    # 2. BleachBit
    Write-Log "Installing BleachBit..."
    winget install --id BleachBit.BleachBit -e --silent --accept-package-agreements --accept-source-agreements

    Write-Log "--- Installation Complete ---" "Green"
    Write-Log "ACTION REQUIRED: Please open 'Malwarebytes' manually and run a scan now." "Magenta"
} catch {
    Write-Log "Error during installation: $($_.Exception.Message)" "Red" "ERROR"
}

Pause-If-Interactive
