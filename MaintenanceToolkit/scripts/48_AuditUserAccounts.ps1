. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Audit User Accounts"
Get-SystemSummary
Write-Section "Local Accounts"

try {
    $users = Get-WmiObject Win32_UserAccount -Filter "LocalAccount=True"

    foreach ($u in $users) {
        $status = if ($u.Disabled) { "Disabled" } else { "Active" }
        $lock = if ($u.Lockout) { "LOCKED" } else { "Unlocked" }

        Write-Host "User: " -NoNewline -ForegroundColor Gray
        Write-Host "$($u.Name)" -NoNewline -ForegroundColor White
        Write-Host " | Status: $status | $lock" -ForegroundColor Gray

        if ($u.PasswordRequired -eq $false) {
             Write-Log "  Warning: Password not required!" "Red"
        }
    }
    Show-Success "Audit Complete."
} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
