# Usage: Run script, type Process Name (e.g., chrome), select Suspend or Resume.
# Check for Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host "Error: This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator." -ForegroundColor Yellow
    if (-not [Console]::IsInputRedirected) { Pause }
    Exit
}
$code = @"
    [DllImport("kernel32.dll")] public static extern IntPtr OpenThread(int dwDesiredAccess, bool bInheritHandle, int dwThreadId);
    [DllImport("kernel32.dll")] public static extern int SuspendThread(IntPtr hThread);
    [DllImport("kernel32.dll")] public static extern int ResumeThread(IntPtr hThread);
    [DllImport("kernel32.dll")] public static extern int CloseHandle(IntPtr hObject);
"@
$func = Add-Type -MemberDefinition $code -Name "Win32" -Namespace Win32 -PassThru

function Suspend-Process ($Name) {
    Get-Process -Name $Name -ErrorAction SilentlyContinue | ForEach-Object {
        $_.Threads | ForEach-Object {
            $h = $func::OpenThread(2, $false, $_.Id)
            $func::SuspendThread($h)
            $func::CloseHandle($h)
        }
    }
    Write-Host "$Name Suspended." -ForegroundColor Yellow
}

function Resume-Process ($Name) {
    Get-Process -Name $Name -ErrorAction SilentlyContinue | ForEach-Object {
        $_.Threads | ForEach-Object {
            $h = $func::OpenThread(2, $false, $_.Id)
            $func::ResumeThread($h)
            $func::CloseHandle($h)
        }
    }
    Write-Host "$Name Resumed." -ForegroundColor Green
}

$proc = Read-Host "Enter Process Name (e.g. chrome, notepad)"
$action = Read-Host "Type 'S' to Suspend or 'R' to Resume"

if ($action -eq "S") { Suspend-Process $proc }
elseif ($action -eq "R") { Resume-Process $proc }