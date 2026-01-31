. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Scanning Recycle Bin"
Get-SystemSummary
Write-Section "Scan Results"

try {
    $shell = New-Object -ComObject Shell.Application
    $bin = $shell.Namespace(0xA) # 0xA is Recycle Bin

    $items = $bin.Items()
    Write-Log "Found $($items.Count) items in Recycle Bin." "Cyan"

    $reportData = @()

    foreach ($item in $items) {
        $size = "Unknown"
        # Try to get size, but Shell items are tricky
        # Usually Size is column 3 or 4 depending on OS

        $reportData += [PSCustomObject]@{
            Name = $item.Name
            OriginalPath = $item.Path
            DateDeleted = $item.ModifyDate
            Type = $item.Type
        }

        Write-Log " - $($item.Name) ($($item.Path))" "Gray"
    }

    if ($items.Count -gt 0) {
        $report = New-Report "Recycle Bin Contents"
        $report | Add-ReportSection "Deleted Items" $reportData "Table"

        $outFile = "$env:USERPROFILE\Desktop\RecycleBinReport_$(Get-Date -Format 'yyyyMMdd_HHmm').html"
        $report | Export-Report-Html $outFile

        Write-Section "Recommendation"
        Show-Success "Report generated: $outFile"
        Write-Log "To empty the Recycle Bin, run 'Nuclear Temp Clean' or right-click it on your Desktop." "Yellow"
        Invoke-Item $outFile
    } else {
        Show-Success "Recycle Bin is empty."
    }
} catch {
    Show-Error "Error scanning Recycle Bin: $($_.Exception.Message)"
}
Pause-If-Interactive
