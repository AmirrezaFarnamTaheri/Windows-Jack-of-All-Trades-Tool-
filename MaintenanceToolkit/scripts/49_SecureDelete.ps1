. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Secure Delete (DoD 5220.22-M)"
Get-SystemSummary
Write-Section "Warning"
Write-Log "This will permanently wipe a file. It cannot be recovered." "Red"

$file = Read-Host "Enter full path to file"

try {
    if (Test-Path $file -PathType Leaf) {
        Write-Section "Wiping"
        Write-Log "Pass 1: Overwriting with Zeros..." "Gray"

        # Simple overwrite implementation
        $len = (Get-Item $file).Length
        $zeros = New-Object byte[] $len
        [io.file]::WriteAllBytes($file, $zeros)

        Write-Log "Pass 2: Overwriting with Ones..." "Gray"
        $ones = New-Object byte[] $len
        for($i=0;$i -lt $len;$i++){$ones[$i]=255}
        [io.file]::WriteAllBytes($file, $ones)

        Write-Log "Pass 3: Overwriting with Random Data..." "Gray"
        $rng = New-Object byte[] $len
        (New-Object Random).NextBytes($rng)
        [io.file]::WriteAllBytes($file, $rng)

        Write-Log "Deleting file..."
        Remove-Item $file -Force
        Show-Success "File securely deleted."
    } else {
        Show-Error "File not found or is a directory."
    }
} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
