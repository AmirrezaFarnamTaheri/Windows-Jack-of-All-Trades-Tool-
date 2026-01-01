. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Take Ownership (Fix Access Denied)"
Get-SystemSummary
Write-Section "Input"

$path = Read-Host "Enter folder path"

try {
    if (Test-Path $path) {
        Write-Section "Processing"
        Write-Log "Taking Ownership..." "Cyan"
        takeown /f "$path" /r /d y

        Write-Log "Granting Admin Permissions..." "Cyan"
        icacls "$path" /grant Administrators:F /t

        Show-Success "Ownership taken and permissions reset."
    } else {
        Show-Error "Path not found."
    }
} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
