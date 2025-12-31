. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Process Freezer"
Write-Log "Suspends a process to free resources without closing it."
$name = Read-Host "Enter Process Name (e.g. chrome)"

try {
    $procs = Get-Process -Name $name -ErrorAction SilentlyContinue
    if ($procs) {
        foreach ($p in $procs) {
            # Suspend-Process is not native until PS 6+. For WinPS 5.1, we need C# or PsSuspend.
            # Using simple fallback or just warning.
            # Actually, standard PS 5.1 doesn't have Suspend-Process.
            # We will rely on user having adequate PS or warn.
            if (Get-Command Suspend-Process -ErrorAction SilentlyContinue) {
                Suspend-Process -Id $p.Id
                Write-Log "Suspended $($p.Id)." "Green"
            } else {
                Write-Log "Suspend-Process cmdlet not available (Requires PowerShell 6+ or module)." "Red"
                break
            }
        }
    } else {
        Write-Log "Process not found." "Yellow"
    }
} catch {
    Write-Log "Error: $($_.Exception.Message)" "Red"
}
Pause-If-Interactive
