. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Retrieving OEM BIOS Windows Key"

$key = (Get-WmiObject -query 'select * from SoftwareLicensingService').OA3xOriginalProductKey

if ($key) {
    Write-Host "BIOS Product Key: $key" -ForegroundColor Green
} else {
    Write-Host "No OEM Key found in BIOS (Retail license used?)." -ForegroundColor Yellow
}