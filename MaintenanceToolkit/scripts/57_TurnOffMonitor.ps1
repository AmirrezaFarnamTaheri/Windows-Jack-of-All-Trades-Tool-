. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Turn Off Monitor"

# PowerShell inline C# to call SendMessage
$code = @"
using System;
using System.Runtime.InteropServices;
public class Monitor {
    [DllImport("user32.dll")]
    public static extern int SendMessage(int hWnd, int hMsg, int wParam, int lParam);
}
"@
Add-Type $code

Write-Log "Turning off monitor in 2 seconds..."
Start-Sleep -Seconds 2
[Monitor]::SendMessage(-1, 0x0112, 0xF170, 2) # SC_MONITORPOWER, 2=Off
Pause-If-Interactive
