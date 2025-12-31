. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Checking Virtualization Support"

try {
    $info = Get-ComputerInfo -Property HyperVisorPresent,HyperVRequirement*

    if ($info.HyperVisorPresent) {
        Write-Log "Hypervisor is running." "Green"
    } else {
        Write-Log "Hypervisor is NOT running." "Yellow"
    }

    Write-Log "Virtualization Firmware Enabled: $($info.HyperVRequirementVirtualizationFirmwareEnabled)"
    Write-Log "Data Execution Prevention Available: $($info.HyperVRequirementDataExecutionPreventionAvailable)"
} catch {
    Write-Log "Error: $($_.Exception.Message)" "Red"
}
Pause-If-Interactive
