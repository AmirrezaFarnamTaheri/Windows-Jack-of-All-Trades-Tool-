. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Detailed System Info Export"
Get-SystemSummary
Write-Section "Execution"

$outFile = "$env:USERPROFILE\Desktop\SystemSpec_$(Get-Date -Format 'yyyyMMdd_HHmm').txt"

try {
    Write-Log "Gathering System Information..." "Cyan"
    "--- SYSTEM SUMMARY ---" | Out-File $outFile -Encoding UTF8

    # OS & Boot
    $os = Get-CimInstance Win32_OperatingSystem
    "OS: $($os.Caption) ($($os.OSArchitecture))" | Out-File $outFile -Append -Encoding UTF8
    "Build: $($os.BuildNumber)" | Out-File $outFile -Append -Encoding UTF8
    "Install Date: $($os.InstallDate)" | Out-File $outFile -Append -Encoding UTF8

    # Security Summary
    "`n--- SECURITY STATUS ---" | Out-File $outFile -Append -Encoding UTF8
    try {
        $av = Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntivirusProduct -ErrorAction SilentlyContinue
        if ($av) {
            foreach ($a in $av) {
                "Antivirus: $($a.displayName)" | Out-File $outFile -Append -Encoding UTF8
            }
        } else {
             "Antivirus: Unknown/ServerOS" | Out-File $outFile -Append -Encoding UTF8
        }
    } catch { "Antivirus Check Failed" | Out-File $outFile -Append -Encoding UTF8 }

    try {
        $tpm = Get-Tpm -ErrorAction SilentlyContinue
        "TPM Ready: $($tpm.TpmReady)" | Out-File $outFile -Append -Encoding UTF8
        "TPM Present: $($tpm.TpmPresent)" | Out-File $outFile -Append -Encoding UTF8
    } catch { "TPM: Access Denied/Missing" | Out-File $outFile -Append -Encoding UTF8 }

    # Secure Boot
    try {
        $secureBoot = Confirm-SecureBootUEFI -ErrorAction SilentlyContinue
        "Secure Boot: $secureBoot" | Out-File $outFile -Append -Encoding UTF8
    } catch { "Secure Boot: Unknown/Legacy" | Out-File $outFile -Append -Encoding UTF8 }

    # Storage & BitLocker
    "`n--- STORAGE & PROTECTION ---" | Out-File $outFile -Append -Encoding UTF8
    $vols = Get-BitLockerVolume -ErrorAction SilentlyContinue
    if ($vols) {
        foreach ($v in $vols) {
            "Volume $($v.MountPoint): $($v.ProtectionStatus) (Lock: $($v.LockStatus))" | Out-File $outFile -Append -Encoding UTF8
        }
    } else {
        "BitLocker: Not Active/Supported" | Out-File $outFile -Append -Encoding UTF8
    }

    Write-Log "Gathering Full Diagnostics (systeminfo)..." "Cyan"
    "`n--- FULL DIAGNOSTICS ---" | Out-File $outFile -Append -Encoding UTF8
    systeminfo | Out-File $outFile -Append -Encoding UTF8

    Show-Success "Detailed system info exported to $outFile"
    Invoke-Item $outFile

} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
