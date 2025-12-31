. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Scanning Recycle Bin"

try {
    $shell = New-Object -ComObject Shell.Application
    $bin = $shell.Namespace(0xA) # 0xA is Recycle Bin

    $items = $bin.Items()
    Write-Log "Found $($items.Count) items in Recycle Bin." "Cyan"

    foreach ($item in $items) {
        Write-Log " - $($item.Name) ($($item.Path))" "White"
    }

    if ($items.Count -gt 0) {
        Write-Log "`nTo empty the Recycle Bin, right-click it on your Desktop." "Yellow"
    }
} catch {
    Write-Log "Error scanning Recycle Bin: $($_.Exception.Message)" "Red"
}
Pause-If-Interactive
