. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Resetting Windows Store & Apps"

Write-Host "1. Clearing Store Cache (WSReset)..." -ForegroundColor Yellow
Start-Process "wsreset.exe" -NoNewWindow -Wait

Write-Host "2. Re-registering Store App..." -ForegroundColor Yellow
Get-AppXPackage *WindowsStore* -AllUsers | Foreach {Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml"}

Write-Host "Store Reset Complete. Try opening it now." -ForegroundColor Green