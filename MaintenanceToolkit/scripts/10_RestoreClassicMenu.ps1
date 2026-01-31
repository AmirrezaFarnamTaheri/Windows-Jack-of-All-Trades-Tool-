. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Restore Classic Context Menu"
Get-SystemSummary

# Only relevant for Win11
$os = Get-CimInstance Win32_OperatingSystem
if ($os.Caption -notmatch "Windows 11") {
    Show-Info "This script is designed for Windows 11. Your OS: $($os.Caption)"
    # Don't exit, user might be on a preview build reported as Win10
}

Write-Section "Execution"

try {
    Write-Log "Applying Registry Fix..." "Yellow"
    $keyPath = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"

    if (-not (Test-Path $keyPath)) {
        New-Item -Path $keyPath -Force -ErrorAction Stop | Out-Null
    }

    # Set default value to empty string
    Set-ItemProperty -Path $keyPath -Name "(default)" -Value "" -ErrorAction Stop

    Write-Log "Restarting Windows Explorer..." "Cyan"
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2

    # Explorer usually restarts itself, but if not:
    if (-not (Get-Process explorer -ErrorAction SilentlyContinue)) {
        Start-Process explorer
    }

    Show-Success "Classic Context Menu Restored."

} catch {
    Show-Error "Error: $($_.Exception.Message)"
}

Pause-If-Interactive
