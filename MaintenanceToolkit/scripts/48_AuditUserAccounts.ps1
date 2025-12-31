. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Auditing Local User Accounts"

Get-LocalUser | Select-Object Name, Enabled, LastLogon, Description | Format-Table -AutoSize

Write-Host "Check for accounts you did not create." -ForegroundColor Yellow
Write-Host "'Guest' and 'DefaultAccount' are normal if disabled (False)." -ForegroundColor DarkGray