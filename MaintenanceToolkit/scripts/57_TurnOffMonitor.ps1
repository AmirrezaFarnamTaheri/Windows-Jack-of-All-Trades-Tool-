. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Turn Off Monitor"
Get-SystemSummary
Write-Section "Execution"

try {
    Write-Log "Turning off monitor signal..."

    # SendMessage(HWND_BROADCAST, WM_SYSCOMMAND, SC_MONITORPOWER, POWER_OFF)
    # 0xFFFF = Broadcast, 0x0112 = SysCommand, 0xF170 = MonitorPower, 2 = Off

    $code = @"
using System;
using System.Runtime.InteropServices;
public class Monitor {
    [DllImport("user32.dll")]
    public static extern int SendMessage(int hWnd, int hMsg, int wParam, int lParam);
}
"@
    Add-Type $code -ErrorAction SilentlyContinue

    if (-not ("Monitor" -as [type])) {
        Show-Error "Monitor API type could not be loaded. Unable to send monitor power signal."
        return
    }

    [Monitor]::SendMessage(0xFFFF, 0x0112, 0xF170, 2) | Out-Null

    Show-Success "Signal sent."
} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
