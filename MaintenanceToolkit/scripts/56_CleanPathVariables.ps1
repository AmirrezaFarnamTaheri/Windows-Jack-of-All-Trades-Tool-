. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Cleaning System PATH Environment Variable"
Get-SystemSummary
Write-Section "Execution"

try {
    $scope = "Machine" # System PATH
    $path = [Environment]::GetEnvironmentVariable("Path", $scope)
    $parts = $path -split ";"
    $newParts = @()

    foreach ($p in $parts) {
        if ([string]::IsNullOrWhiteSpace($p)) { continue }
        if (Test-Path $p) {
            $newParts += $p
        } else {
            Write-Log "Removed dead path: $p" "Yellow"
        }
    }

    # Remove duplicates
    $finalParts = $newParts | Select-Object -Unique
    $newPath = $finalParts -join ";"

    if ($newPath -ne $path) {
        [Environment]::SetEnvironmentVariable("Path", $newPath, $scope)
        Show-Success "PATH Cleaned and Updated."
    } else {
        Show-Success "PATH is already clean."
    }

} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
