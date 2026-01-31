. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Hardware Monitor (Legacy)"
Get-SystemSummary

Write-Section "Notice"
Write-Log "This script has been superseded by the Dashboard in the main application." "Yellow"
Write-Log "Please use the 'Dashboard' tab for real-time monitoring." "Cyan"

# Just run a quick loop for old times sake if user really wants it
Write-Log "Press Ctrl+C to exit." "Gray"

try {
    while ($true) {
        $cpu = (Get-WmiObject Win32_Processor).LoadPercentage
        $ram = Get-WmiObject Win32_OperatingSystem
        $free = [math]::Round($ram.FreePhysicalMemory / 1024, 0)
        $total = [math]::Round($ram.TotalVisibleMemorySize / 1024, 0)
        $used = $total - $free
        $pct = [math]::Round(($used / $total) * 100, 1)

        Write-Host "`rCPU: $cpu% | RAM: $used MB / $total MB ($pct%)   " -NoNewline
        Start-Sleep -Seconds 1

        if ([Console]::KeyAvailable) { break }
    }
} catch {}
