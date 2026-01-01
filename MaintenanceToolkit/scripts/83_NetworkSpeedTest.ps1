. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Network Download Speed Test"
Get-SystemSummary
Write-Section "Testing"

try {
    $url = "http://speedtest.tele2.net/100MB.zip" # Common test file
    $tempFile = "$env:TEMP\speedtest.tmp"

    Write-Log "Downloading test file (100 MB)..." "Cyan"

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        Invoke-WebRequest -Uri $url -OutFile $tempFile -ErrorAction Stop
    } catch {
        Show-Error "Download failed. Check internet connection."
        return
    }
    $sw.Stop()

    $sizeBytes = 100 * 1024 * 1024 # 100MB
    $seconds = $sw.Elapsed.TotalSeconds
    $mbps = ($sizeBytes * 8) / ($seconds * 1000 * 1000) # Mbps

    Write-Section "Results"
    Write-Log "Time: $([math]::Round($seconds, 2)) seconds" "White"
    Write-Log "Speed: $([math]::Round($mbps, 2)) Mbps" "Green"

    if (Test-Path $tempFile) { Remove-Item $tempFile -Force }

    Show-Success "Test Complete."

} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
