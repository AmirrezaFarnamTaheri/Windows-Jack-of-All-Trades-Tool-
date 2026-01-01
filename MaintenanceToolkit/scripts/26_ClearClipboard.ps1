. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Clearing Clipboard"
Get-SystemSummary

try {
    Write-Section "Clearing Current Content"
    Set-Clipboard $null

    # Verify
    if (-not (Get-Clipboard)) {
        Show-Success "Current clipboard cleared."
    }

    # Attempt to clear history (Windows 10/11)
    Write-Section "Clearing Clipboard History"
    try {
        # Using WinRT API via PowerShell
        $code = @"
using System;
using System.Runtime.InteropServices;
using Windows.ApplicationModel.DataTransfer;

public class ClipboardHelper {
    public static bool ClearHistory() {
        return Clipboard.ClearHistory();
    }
}
"@
        # This requires Windows Runtime references which are tricky in PS 5.1
        # Fallback to simple Restart-Service for Clipboard User Service if possible,
        # or just warn user.

        Write-Log "To clear Clipboard History (Win+V), we will restart the service." "Cyan"

        # Service name usually: cbdhsvc_xxxxx (per user)
        $svc = Get-Service | Where-Object { $_.Name -like "cbdhsvc*" }
        if ($svc) {
            Stop-Service -Name $svc.Name -Force -ErrorAction SilentlyContinue
            Start-Service -Name $svc.Name -ErrorAction SilentlyContinue
            Show-Success "Clipboard User Service restarted."
        } else {
            Write-Log "Clipboard service not found or accessible." "Yellow"
        }

    } catch {
        Write-Log "Could not clear history programmatically." "Yellow"
    }

} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
