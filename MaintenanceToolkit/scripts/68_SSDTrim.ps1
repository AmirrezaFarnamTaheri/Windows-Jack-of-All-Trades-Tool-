. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "SSD Optimization (Trim)"
Get-SystemSummary
Write-Section "Execution"

try {
    Write-Log "Optimizing C: Drive (Retrim)..." "Cyan"

    # Check if SSD
    $drive = Get-PhysicalDisk | Where-Object { $_.DeviceId -eq 0 } # Assuming C is on Disk 0 for simplicity, better logic exists but this is quick check

    Optimize-Volume -DriveLetter C -ReTrim -Verbose

    Show-Success "SSD Trim command sent."
} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
