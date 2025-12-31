. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Checking Windows Activation"

try {
    Start-Process slmgr.vbs -ArgumentList "/xpr"
    Write-Log "Activation status popup launched." "Green"
} catch {
    Write-Log "Error: $($_.Exception.Message)" "Red"
}
Pause-If-Interactive
