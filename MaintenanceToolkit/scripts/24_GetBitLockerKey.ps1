. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Retrieving BitLocker Recovery Keys"
Get-SystemSummary
Write-Section "Scanning Volumes"

try {
    $volumes = Get-BitLockerVolume -ErrorAction SilentlyContinue
    if (-not $volumes) {
        Write-Log "No BitLocker volumes found or BitLocker is not available." "Yellow"
        if (-not [Console]::IsInputRedirected) { Pause }
        return
    }

    $exportContent = "BitLocker Recovery Keys - Exported $(Get-Date)`r`n"
    $exportContent += "=================================================`r`n"
    $foundKeys = $false

    foreach ($vol in $volumes) {
        $status = if ($vol.ProtectionStatus -eq "On") { "Encrypted" } else { "Decrypted/Suspended" }
        Write-Log "Checking Volume: $($vol.MountPoint) [$status]" "Cyan"

        if ($vol.ProtectionStatus -eq "On") {
            $key = $vol.KeyProtector | Where-Object { $_.KeyProtectorType -eq "RecoveryPassword" }
            if ($key) {
                $msg = "Volume: $($vol.MountPoint)`r`nID: $($key.KeyProtectorId)`r`nRecovery Key: $($key.RecoveryPassword)`r`n"
                Write-Log "$msg" "Green"
                $exportContent += $msg + "`r`n"
                $foundKeys = $true
            } else {
                Write-Log "  No Recovery Password protector found for this volume." "Yellow"
            }
        }
    }

    Write-Section "Export"
    if ($foundKeys) {
        $desktop = [Environment]::GetFolderPath("Desktop")
        $outFile = "$desktop\BitLocker_Keys_$(Get-Date -Format 'yyyyMMdd-HHmm').txt"
        $exportContent | Out-File -FilePath $outFile -Encoding UTF8
        Show-Success "Keys exported to: $outFile"
        Write-Log "KEEP THIS FILE SAFE." "Red"
    } else {
        Write-Log "No keys found to export." "Yellow"
    }

} catch {
    Show-Error "Error retrieving BitLocker info: $($_.Exception.Message)"
}

Pause-If-Interactive
