. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Starting Network Stack Reset"

Write-Log "This will reset your network adapters. Internet connection will be lost temporarily." "Yellow"

try {
    # 1. Release/Renew (Optional, often fails if disconnected, so we skip error)
    Write-Log "Refreshing DHCP Lease..."
    Start-Process ipconfig -ArgumentList "/release" -Wait -NoNewWindow
    Start-Process ipconfig -ArgumentList "/renew" -Wait -NoNewWindow

    # 2. Flush DNS
    Write-Log "Flushing DNS Cache..."
    Start-Process ipconfig -ArgumentList "/flushdns" -Wait -NoNewWindow

    # 3. Reset TCP/IP
    Write-Log "Resetting TCP/IP Stack..."
    $logFile = "$env:TEMP\netsh_reset.log"
    Start-Process netsh -ArgumentList "int ip reset `"$logFile`"" -Wait -NoNewWindow
    if (Test-Path $logFile) { Remove-Item $logFile -ErrorAction SilentlyContinue }

    # 4. Reset Winsock
    Write-Log "Resetting Winsock Catalog..."
    Start-Process netsh -ArgumentList "winsock reset" -Wait -NoNewWindow

    # 5. Clear ARP Cache
    Write-Log "Clearing ARP Cache..."
    Start-Process netsh -ArgumentList "interface ip delete arpcache" -Wait -NoNewWindow

    Write-Log "--- Network Reset Complete ---" "Green"
    Write-Log "ACTION REQUIRED: Restart your computer to finalize changes." "Magenta"
    Write-Log "Note: You may need to re-enter Wi-Fi passwords if profiles were corrupted." "Gray"

} catch {
    Write-Log "Error during network reset: $($_.Exception.Message)" "Red" "ERROR"
}

Pause-If-Interactive
