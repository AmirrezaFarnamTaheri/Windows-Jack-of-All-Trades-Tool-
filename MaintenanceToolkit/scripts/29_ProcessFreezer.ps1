. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Process Freezer"
Write-Log "Suspends a process to free resources without closing it."
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
                Write-Log "Success." "Green"
            } else {
                Write-Log "Failed to open handle for PID $($p.Id)." "Red"
            }
        }
        Write-Log "`nTo Resume, restart the app or use Resource Monitor." "Yellow"
    } else {
        Write-Log "Process '$name' not found." "Yellow"
    }
} catch {
    Write-Log "Error: $($_.Exception.Message)" "Red"
}
Pause-If-Interactive
