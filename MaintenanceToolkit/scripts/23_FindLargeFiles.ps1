. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Find Large Files (>1GB)"
$path = Read-Host "Enter path to scan (default: $env:USERPROFILE)"
if ([string]::IsNullOrWhiteSpace($path)) { $path = $env:USERPROFILE }

try {
    if (Test-Path $path) {
        Write-Log "Scanning $path (This takes time)..."
        Get-ChildItem -Path $path -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Length -gt 1GB } |
        Sort-Object Length -Descending |
        ForEach-Object {
            $sizeGB = [math]::Round($_.Length / 1GB, 2)
            Write-Log "$sizeGB GB - $($_.FullName)" "White"
        }
    } else {
        Write-Log "Path not found." "Red"
    }
} catch {
    Write-Log "Error: $($_.Exception.Message)" "Red"
}
Pause-If-Interactive
