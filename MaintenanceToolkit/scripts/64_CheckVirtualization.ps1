. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Checking Virtualization Support"
Get-SystemSummary
Write-Section "Check Results"

try {
    $info = Get-ComputerInfo -Property HyperVisorPresent,HyperVRequirement*

    if ($info.HyperVisorPresent) {
        Show-Success "Hypervisor is running."
    } else {
        Write-Log "Hypervisor is NOT running." "Yellow"
    }

    Write-Log "Virtualization Firmware Enabled: $($info.HyperVRequirementVirtualizationFirmwareEnabled)"
    Write-Log "Data Execution Prevention Available: $($info.HyperVRequirementDataExecutionPreventionAvailable)"
} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
