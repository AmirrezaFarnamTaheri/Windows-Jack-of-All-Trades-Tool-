. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Audit User Accounts"
Get-SystemSummary
Write-Section "Local Accounts"

try {
    $users = Get-WmiObject Win32_UserAccount -Filter "LocalAccount=True"
    $userReport = @()

    foreach ($u in $users) {
        $status = if ($u.Disabled) { "<span class='status-warn'>Disabled</span>" } else { "<span class='status-pass'>Active</span>" }
        $lock = if ($u.Lockout) { "<span class='status-fail'>LOCKED</span>" } else { "Unlocked" }

        $pwdReq = "Yes"
        if ($u.PasswordRequired -eq $false) {
             $pwdReq = "<span class='status-fail'>NO (!)</span>"
        }

        $userReport += [PSCustomObject]@{
            Username = $u.Name
            FullName = $u.FullName
            Status = $status
            Lockout = $lock
            "Password Required" = $pwdReq
            SID = $u.SID
        }
    }

    $report = New-Report "Local User Account Audit"
    $report | Add-ReportSection "Local Accounts" $userReport "Table"

    $outFile = "$env:USERPROFILE\Desktop\UserAudit_$(Get-Date -Format 'yyyyMMdd_HHmm').html"
    $report | Export-Report-Html $outFile

    Show-Success "Audit Complete. Report saved to $outFile"
    Invoke-Item $outFile

} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
