. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Audit User Accounts"
Get-SystemSummary

try {
    Write-Section "Scanning Local Accounts"
    $users = Get-WmiObject Win32_UserAccount -Filter "LocalAccount=True"
    $userReport = @()

    foreach ($u in $users) {
        $status = if ($u.Disabled) { "<span class='status-warn'>Disabled</span>" } else { "<span class='status-pass'>Active</span>" }
        $lock = if ($u.Lockout) { "<span class='status-fail'>LOCKED</span>" } else { "Unlocked" }

        $pwdReq = "Yes"
        if ($u.PasswordRequired -eq $false) {
             $pwdReq = "<span class='status-fail'>NO (!)</span"
        }

        # Try to get Last Logon (Tricky for local accounts, usually needs NetAPI32 or parsing 'net user')
        # We'll use 'net user' output parsing as a robust fallback
        $lastLogon = "Unknown"
        try {
            $netUser = net user $u.Name 2>$null
            $line = $netUser | Select-String "Last logon"
            if ($line) { $lastLogon = $line.ToString().Split(@("logon"), [StringSplitOptions]::RemoveEmptyEntries)[1].Trim() }
        } catch {}

        $userReport += [PSCustomObject]@{
            Username = $u.Name
            FullName = $u.FullName
            Status = $status
            Lockout = $lock
            "Password Req" = $pwdReq
            "Last Logon" = $lastLogon
            SID = $u.SID
        }

        Write-Log "User: $($u.Name) [$($u.Disabled ? 'Disabled' : 'Active')]" "White"
    }

    $report = New-Report "Local User Account Audit"
    $report | Add-ReportSection "Local Accounts" $userReport "Table"

    $outFile = "$env:USERPROFILE\Desktop\UserAudit_$(Get-Date -Format 'yyyyMMdd_HHmm').html"
    $report | Export-Report-Html $outFile

    Show-Success "Audit Complete. Report saved."
    Invoke-Item $outFile

} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
