. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Checking Windows Activation Status"
cscript //nologo $env:SystemRoot\System32\slmgr.vbs /xpr
cscript //nologo $env:SystemRoot\System32\slmgr.vbs /dli