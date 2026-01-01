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

        # Overwrite in chunks to avoid memory issues with large files
        $stream = [System.IO.File]::Open($file, 'Open', 'Write')
        $chunkSize = 4MB # 4MB chunks
        $len = $stream.Length
        $chunks = [math]::Ceiling($len / $chunkSize)
        $chunk = New-Object byte[] $chunkSize

        # Pass 1: Zeros
        Write-Log "Pass 1: Overwriting with Zeros..." "Gray"
        $stream.Seek(0, 'Begin') | Out-Null
        [System.Array]::Clear($chunk, 0, $chunkSize)
        for ($i = 0; $i -lt $chunks; $i++) {
            $bytesToWrite = [math]::Min($chunkSize, $len - ($i * $chunkSize))
            $stream.Write($chunk, 0, $bytesToWrite)
        }

        # Pass 2: Ones
        Write-Log "Pass 2: Overwriting with Ones..." "Gray"
        $stream.Seek(0, 'Begin') | Out-Null
        for ($j=0; $j -lt $chunkSize; $j++) { $chunk[$j] = 255 }
        for ($i = 0; $i -lt $chunks; $i++) {
            $bytesToWrite = [math]::Min($chunkSize, $len - ($i * $chunkSize))
            $stream.Write($chunk, 0, $bytesToWrite)
        }

        # Pass 3: Random (Cryptographically Secure)
        Write-Log "Pass 3: Overwriting with Crypto Random Data..." "Gray"
        $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
        $stream.Seek(0, 'Begin') | Out-Null
        for ($i = 0; $i -lt $chunks; $i++) {
            $rng.GetBytes($chunk)
            $bytesToWrite = [math]::Min($chunkSize, $len - ($i * $chunkSize))
            $stream.Write($chunk, 0, $bytesToWrite)
        }

        $stream.Close()
        $stream.Dispose()

        Write-Log "Deleting file..."
        Remove-Item $file -Force
        Show-Success "File securely deleted."
    } else {
        Show-Error "File not found or is a directory."
    }
} catch {
    if ($stream) { $stream.Close(); $stream.Dispose() }
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
