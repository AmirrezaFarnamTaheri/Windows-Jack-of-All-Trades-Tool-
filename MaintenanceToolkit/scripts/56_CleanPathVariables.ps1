. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Cleaning System PATH"

$path = [Environment]::GetEnvironmentVariable("Path", "Machine")
$entries = $path -split ";"
$newPath = @()

foreach ($entry in $entries) {
    if (Test-Path $entry) {
        $newPath += $entry
    } else {
        Write-Host "Removing Dead Path: $entry" -ForegroundColor Red
    }
}

$final = $newPath -join ";"
[Environment]::SetEnvironmentVariable("Path", $final, "Machine")
Write-Host "PATH Cleaned." -ForegroundColor Green