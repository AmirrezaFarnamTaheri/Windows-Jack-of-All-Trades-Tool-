. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Restoring Classic Right-Click Menu"
Get-SystemSummary
Write-Section "Execution"

try {
    Write-Log "Applying Registry Fix for Windows 11..." "Yellow"
    $key = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"

    if (-not (Test-Path $key)) {
        New-Item -Path $key -Force | Out-Null
    }

    # Set default value to empty string to enable classic menu
    Set-ItemProperty -Path $key -Name "(default)" -Value "" -ErrorAction Stop

    Write-Log "Registry updated. Restarting Explorer..." "Cyan"
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2

    if (-not (Get-Process explorer -ErrorAction SilentlyContinue)) {
        Start-Process explorer
    }

    Show-Success "Classic Context Menu Restored."

} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
