. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Exporting Installed Software List"

$path = "$env:USERPROFILE\Desktop\InstalledApps.csv"

$keys = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
Get-ItemProperty $keys -ErrorAction SilentlyContinue |
    Select-Object DisplayName, DisplayVersion, Publisher, InstallDate |
    Where-Object { $_.DisplayName -ne $null } |
    Sort-Object DisplayName |
    Export-Csv -Path $path -NoTypeInformation

Write-Host "List saved to Desktop as 'InstalledApps.csv'" -ForegroundColor Green