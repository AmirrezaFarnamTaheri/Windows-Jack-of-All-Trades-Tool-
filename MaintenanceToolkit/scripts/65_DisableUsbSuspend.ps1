. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Disabling USB Selective Suspend"

try {
    # This usually requires registry hacking per power plan or powercfg
    Write-Log "Disabling USB Suspend on active scheme..."
    powercfg /SETACVALUEINDEX SCHEME_CURRENT 2a737441-1930-4402-8d77-b2beb1463445 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
    powercfg /SETDCVALUEINDEX SCHEME_CURRENT 2a737441-1930-4402-8d77-b2beb1463445 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
    powercfg /SetActive SCHEME_CURRENT

    Write-Log "USB Selective Suspend Disabled." "Green"
} catch {
    Write-Log "Error: $($_.Exception.Message)" "Red"
}
Pause-If-Interactive
