. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Disabling USB Selective Suspend"

try {
    # GUIDs:
    # USB Settings Subgroup: 2a737441-1930-4402-8d77-b2beb1463538
    # USB Selective Suspend: 48e6b7a6-50f5-4782-a5d4-53bb8f07e226

    Write-Log "Disabling USB Suspend on active scheme..."

    # AC Power
    powercfg /SETACVALUEINDEX SCHEME_CURRENT 2a737441-1930-4402-8d77-b2beb1463538 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
    # DC Power (Battery)
    powercfg /SETDCVALUEINDEX SCHEME_CURRENT 2a737441-1930-4402-8d77-b2beb1463538 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0

    powercfg /SetActive SCHEME_CURRENT

    Write-Log "USB Selective Suspend Disabled." "Green"
} catch {
    Write-Log "Error: $($_.Exception.Message)" "Red"
}
Pause-If-Interactive
