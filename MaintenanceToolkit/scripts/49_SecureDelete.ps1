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
        $len = (Get-Item $file).Length
        $chunkSize = 1048576 * 64  # 64 MB
        $fs = [System.IO.File]::OpenWrite($file)

        try {
            # Pass 1: Zeros
            Write-Log "Pass 1: Overwriting with Zeros..." "Gray"
            $zeroBuf = New-Object byte[] ([Math]::Min($chunkSize, $len))
            # zeroBuf is already zeros
            $written = 0L
            $fs.Seek(0, "Begin") | Out-Null
            while ($written -lt $len) {
                $count = [Math]::Min($zeroBuf.Length, $len - $written)
                $fs.Write($zeroBuf, 0, $count)
                $written += $count
            }
            $fs.Flush()

            # Pass 2: Ones
            Write-Log "Pass 2: Overwriting with Ones..." "Gray"
            $oneBuf = New-Object byte[] $zeroBuf.Length
            for($i=0; $i -lt $oneBuf.Length; $i++) { $oneBuf[$i] = 255 }

            $written = 0L
            $fs.Seek(0, "Begin") | Out-Null
            while ($written -lt $len) {
                $count = [Math]::Min($oneBuf.Length, $len - $written)
                $fs.Write($oneBuf, 0, $count)
                $written += $count
            }
            $fs.Flush()

            # Pass 3: Random
            Write-Log "Pass 3: Overwriting with Random Data..." "Gray"
            $rnd = New-Object Random
            $randBuf = New-Object byte[] $zeroBuf.Length

            $written = 0L
            $fs.Seek(0, "Begin") | Out-Null
            while ($written -lt $len) {
                $rnd.NextBytes($randBuf)
                $count = [Math]::Min($randBuf.Length, $len - $written)
                $fs.Write($randBuf, 0, $count)
                $written += $count
            }
            $fs.Flush()

        } finally {
            $fs.Close()
            $fs.Dispose()
        }

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
