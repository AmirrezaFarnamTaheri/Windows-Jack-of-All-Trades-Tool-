Write-Host "--- Auditing Local User Accounts ---" -ForegroundColor Cyan

Get-LocalUser | Select-Object Name, Enabled, LastLogon, Description | Format-Table -AutoSize

Write-Host "Check for accounts you did not create." -ForegroundColor Yellow
Write-Host "'Guest' and 'DefaultAccount' are normal if disabled (False)." -ForegroundColor DarkGray