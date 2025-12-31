Write-Host "--- Checking Windows Activation Status ---" -ForegroundColor Cyan
cscript //nologo $env:SystemRoot\System32\slmgr.vbs /xpr
cscript //nologo $env:SystemRoot\System32\slmgr.vbs /dli