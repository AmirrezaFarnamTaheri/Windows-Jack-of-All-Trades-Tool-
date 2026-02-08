. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "File Hash Verifier"
Get-SystemSummary

function Get-Hashes ($Path) {
    if (-not (Test-Path $Path -PathType Leaf)) { return $null }

    $fileInfo = Get-Item $Path
    $size = Format-Size $fileInfo.Length

    Write-Log "Hashing: $($fileInfo.Name) ($size)" "Cyan"

    $md5 = Get-FileHash -Path $Path -Algorithm MD5
    $sha1 = Get-FileHash -Path $Path -Algorithm SHA1
    $sha256 = Get-FileHash -Path $Path -Algorithm SHA256

    return [ordered]@{
        File = $fileInfo.Name
        Size = $size
        MD5 = $md5.Hash
        SHA1 = $sha1.Hash
        SHA256 = $sha256.Hash
    }
}

Write-Section "Instructions"
Write-Host "Enter the full path to a file to verify its integrity." -ForegroundColor Gray
Write-Host "You can drag and drop the file into this window." -ForegroundColor Gray
Write-Host "Type 'Q' to quit." -ForegroundColor Yellow

while ($true) {
    Write-Host ""
    $inputPath = Read-Host "File Path"

    if ([string]::IsNullOrWhiteSpace($inputPath)) { continue }
    if ($inputPath -eq 'Q' -or $inputPath -eq 'q') { break }

    # Remove quotes if drag-dropped
    $inputPath = $inputPath -replace '"',''

    if (Test-Path $inputPath) {
        try {
            $hashes = Get-Hashes $inputPath

            Write-Host "----------------------------------------" -ForegroundColor DarkGray
            Write-Host "File:   " -NoNewline -ForegroundColor White; Write-Host $hashes.File -ForegroundColor Green
            Write-Host "Size:   " -NoNewline -ForegroundColor White; Write-Host $hashes.Size -ForegroundColor Gray
            Write-Host "MD5:    " -NoNewline -ForegroundColor White; Write-Host $hashes.MD5 -ForegroundColor Yellow
            Write-Host "SHA1:   " -NoNewline -ForegroundColor White; Write-Host $hashes.SHA1 -ForegroundColor Yellow
            Write-Host "SHA256: " -NoNewline -ForegroundColor White; Write-Host $hashes.SHA256 -ForegroundColor Yellow
            Write-Host "----------------------------------------" -ForegroundColor DarkGray

            # Compare
            $compare = Read-Host "Paste hash to compare (Optional)"
            if (-not [string]::IsNullOrWhiteSpace($compare)) {
                $clean = $compare.Trim().ToUpper()
                if ($clean -eq $hashes.MD5) { Show-Success "MATCH (MD5)" }
                elseif ($clean -eq $hashes.SHA1) { Show-Success "MATCH (SHA1)" }
                elseif ($clean -eq $hashes.SHA256) { Show-Success "MATCH (SHA256)" }
                else { Show-Error "NO MATCH FOUND" }
            }

        } catch {
            Show-Error "Error hashing file: $($_.Exception.Message)"
        }
    } else {
        Show-Error "File not found."
    }
}
