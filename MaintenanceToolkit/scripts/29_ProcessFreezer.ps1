. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Process Freezer"
Get-SystemSummary
Write-Section "Instructions"
Write-Log "Suspends a process to free resources without closing it." "Cyan"

$name = Read-Host "Enter Process Name (e.g. chrome)"

# Define P/Invoke for Suspend/Resume
$code = @"
using System;
using System.Runtime.InteropServices;

public class ProcessUtil {
    [DllImport("kernel32.dll")]
    public static extern IntPtr OpenProcess(int dwDesiredAccess, bool bInheritHandle, int dwProcessId);

    [DllImport("ntdll.dll")]
    public static extern uint NtSuspendProcess(IntPtr processHandle);

    [DllImport("ntdll.dll")]
    public static extern uint NtResumeProcess(IntPtr processHandle);

    [DllImport("kernel32.dll")]
    public static extern bool CloseHandle(IntPtr handle);
}
"@

try {
    Add-Type $code -ErrorAction SilentlyContinue
} catch {
    # Type might already be added in session
}

try {
    $procs = Get-Process -Name $name -ErrorAction SilentlyContinue
    if ($procs) {
        foreach ($p in $procs) {
            $handle = [ProcessUtil]::OpenProcess(0x0800, $false, $p.Id) # 0x0800 = SUSPEND_RESUME

            if ($handle -ne [IntPtr]::Zero) {
                Write-Log "Suspending $($p.ProcessName) (PID: $($p.Id))..."
                [ProcessUtil]::NtSuspendProcess($handle) | Out-Null
                [ProcessUtil]::CloseHandle($handle) | Out-Null
                Show-Success "Suspended $($p.ProcessName) ($($p.Id))"
            } else {
                Show-Error "Failed to open handle for PID $($p.Id)."
            }
        }
        Write-Log "`nTo Resume, restart the app or use Resource Monitor." "Yellow"
    } else {
        Show-Error "Process '$name' not found."
    }
} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
