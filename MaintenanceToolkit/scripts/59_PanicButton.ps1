. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
$obj = New-Object -ComObject WScript.Shell
$obj.SendKeys([char]173)

Set-Clipboard -Value $null

$shell = New-Object -ComObject Shell.Application
$shell.MinimizeAll()