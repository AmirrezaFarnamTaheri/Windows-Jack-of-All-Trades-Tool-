. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Clear Browser Caches"
Get-SystemSummary
Write-Section "Warning"
Write-Log "This will close all browsers and delete cache files." "Yellow"
Write-Log "Cookies and History will NOT be deleted." "Cyan"

$confirm = Read-Host "Type 'Y' to continue"
if ($confirm -ne 'Y') { Exit }

try {
    # 1. Chrome
    if (Get-Process "chrome" -ErrorAction SilentlyContinue) {
        Write-Log "Closing Chrome..."
        Stop-Process -Name "chrome" -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
    }
    $chromeCache = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache"
    if (Test-Path $chromeCache) {
        Remove-Item "$chromeCache\*" -Recurse -Force -ErrorAction SilentlyContinue
        Show-Success "Chrome Cache Cleared."
    }

    # 2. Edge
    if (Get-Process "msedge" -ErrorAction SilentlyContinue) {
        Write-Log "Closing Edge..."
        Stop-Process -Name "msedge" -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
    }
    $edgeCache = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache"
    if (Test-Path $edgeCache) {
        Remove-Item "$edgeCache\*" -Recurse -Force -ErrorAction SilentlyContinue
        Show-Success "Edge Cache Cleared."
    }

    # 3. Firefox
    if (Get-Process "firefox" -ErrorAction SilentlyContinue) {
        Write-Log "Closing Firefox..."
        Stop-Process -Name "firefox" -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
    }
    # Firefox profiles vary
    $ffPath = "$env:LOCALAPPDATA\Mozilla\Firefox\Profiles"
    if (Test-Path $ffPath) {
        Get-ChildItem $ffPath -Directory | ForEach-Object {
            $c = "$($_.FullName)\cache2"
            if (Test-Path $c) {
                Remove-Item "$c\*" -Recurse -Force -ErrorAction SilentlyContinue
                Show-Success "Firefox Cache Cleared ($($_.Name))."
            }
        }
    }

    Show-Success "Browser cleanup finished."

} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
