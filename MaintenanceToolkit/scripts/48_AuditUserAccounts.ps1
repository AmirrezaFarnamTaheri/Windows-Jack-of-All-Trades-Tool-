. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Auditing Local User Accounts"

try {
    $users = Get-LocalUser
    foreach ($u in $users) {
        $status = if ($u.Enabled) { "Enabled" } else { "Disabled" }
        Write-Log "User: $($u.Name) | Status: $status | LastLogon: $($u.LastLogon)" "White"
    }
} catch {
    Write-Log "Error: $($_.Exception.Message)" "Red"
}
Pause-If-Interactive
