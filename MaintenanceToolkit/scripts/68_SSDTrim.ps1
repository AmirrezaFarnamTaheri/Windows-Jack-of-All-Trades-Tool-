. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "SSD Optimization (Trim)"
Get-SystemSummary
Write-Section "Execution"

try {
    Write-Log "Optimizing C: Drive (Retrim)..." "Cyan"

    # Check if C: is on an SSD before trimming
    $partition = Get-Partition -DriveLetter C -ErrorAction Stop
    $disk = Get-Disk -Number $partition.DiskNumber -ErrorAction Stop

    $physical = Get-PhysicalDisk | Where-Object { $_.FriendlyName -eq $disk.FriendlyName } | Select-Object -First 1
    if (-not $physical -or $physical.MediaType -ne 'SSD') {
        Write-Log "C: is not detected as SSD (MediaType: $($physical.MediaType)). Skipping ReTrim." "Yellow"
        Pause-If-Interactive
        return
    }

    Optimize-Volume -DriveLetter C -ReTrim -Verbose -ErrorAction Stop

    Show-Success "SSD Trim completed."
} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
