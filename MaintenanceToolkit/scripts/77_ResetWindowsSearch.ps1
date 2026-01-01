. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Reset Windows Search Index"
Get-SystemSummary
Write-Section "Execution"

try {
    Write-Log "Stopping Windows Search Service..." "Yellow"
    Stop-ServiceSafe "wsearch" -ErrorAction SilentlyContinue

    $searchDataPath = "$env:ProgramData\Microsoft\Search\Data\Applications\Windows"
    $searchRegKey = "HKLM:\SOFTWARE\Microsoft\Windows Search"

    if (Test-Path $searchDataPath) {
        Write-Log "Deleting Search Database..." "Cyan"
        Remove-Item "$searchDataPath\*" -Recurse -Force -ErrorAction SilentlyContinue
    }

    Write-Log "Resetting Registry SetupCompletedSuccessfully flag..."
    Set-ItemProperty -Path $searchRegKey -Name "SetupCompletedSuccessfully" -Value 0 -ErrorAction SilentlyContinue

    Write-Log "Restarting Windows Search Service..." "Cyan"
    Start-Service "wsearch" -ErrorAction SilentlyContinue

    Show-Success "Windows Search Index has been reset. Re-indexing will occur in the background."

} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
