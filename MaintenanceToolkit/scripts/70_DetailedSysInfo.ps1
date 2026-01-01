. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Detailed System Info Export"
Get-SystemSummary
Write-Section "Execution"

try {
    Write-Log "Gathering System Information..." "Cyan"

    New-Report "Detailed System Information"

    # OS & Boot
    $os = Get-CimInstance Win32_OperatingSystem
    Add-ReportSection "Operating System" @{
        "OS Name" = "$($os.Caption)"
        "Architecture" = "$($os.OSArchitecture)"
        "Version" = "$($os.Version)"
        "Build Number" = "$($os.BuildNumber)"
        "Install Date" = "$($os.InstallDate)"
        "Last Boot" = "$($os.LastBootUpTime)"
    } "KeyValue"

    # Hardware
    $cpu = Get-CimInstance Win32_Processor
    $ramTotal = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
    $ramFree = [math]::Round($os.FreePhysicalMemory / 1MB, 2)

    Add-ReportSection "Hardware Summary" @{
        "Processor" = "$($cpu.Name)"
        "Cores / Threads" = "$($cpu.NumberOfCores) / $($cpu.NumberOfLogicalProcessors)"
        "Total RAM" = "$ramTotal GB"
        "Free RAM" = "$ramFree GB"
    } "KeyValue"

    # Security Summary
    $secInfo = [ordered]@{}
    try {
        $av = Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntivirusProduct -ErrorAction Stop
        if ($av) {
            foreach ($a in $av) {
                $status = if ($a.productState -match "1$") {"Enabled"} else {"Disabled/Unknown"}
                $secInfo["Antivirus"] = "$($a.displayName) ($status)"
            }
        } else {
             $secInfo["Antivirus"] = "Not Found"
        }
    } catch { $secInfo["Antivirus"] = "Check Failed" }

    try {
        $tpm = Get-Tpm -ErrorAction SilentlyContinue
        $secInfo["TPM Present"] = "$($tpm.TpmPresent)"
        $secInfo["TPM Ready"] = "$($tpm.TpmReady)"
    } catch { $secInfo["TPM"] = "Access Denied/Missing" }

    try {
        $secureBoot = Confirm-SecureBootUEFI -ErrorAction SilentlyContinue
        $secInfo["Secure Boot"] = "$secureBoot"
    } catch { $secInfo["Secure Boot"] = "Unknown/Legacy" }

    Add-ReportSection "Security Status" $secInfo "KeyValue"

    # Storage & BitLocker
    $volList = @()
    $vols = Get-BitLockerVolume -ErrorAction SilentlyContinue
    if ($vols) {
        foreach ($v in $vols) {
            $volList += [PSCustomObject]@{
                MountPoint = $v.MountPoint
                VolumeStatus = $v.VolumeStatus
                ProtectionStatus = $v.ProtectionStatus
                LockStatus = $v.LockStatus
                EncryptionMethod = $v.EncryptionMethod
            }
        }
        Add-ReportSection "BitLocker Status" $volList "Table"
    } else {
        Add-ReportSection "BitLocker Status" "BitLocker management is not available or no protected volumes found."
    }

    # Network Adapters
    $netAdapters = Get-NetAdapter -Physical | Select-Object Name, InterfaceDescription, Status, MacAddress, LinkSpeed
    Add-ReportSection "Network Adapters" $netAdapters "Table"

    # Services
    $services = Get-Service | Where-Object {$_.Status -eq 'Running'} | Select-Object Name, DisplayName, StartType | Sort-Object Name
    # Limiting for brevity in HTML if too long, but let's include all running
    Add-ReportSection "Running Services" $services "Table"

    # Export
    $outFile = "$env:USERPROFILE\Desktop\SystemSpec_$(Get-Date -Format 'yyyyMMdd_HHmm').html"
    Export-Report-Html $outFile

    Show-Success "Detailed system info exported to $outFile"
    Invoke-Item $outFile

} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
