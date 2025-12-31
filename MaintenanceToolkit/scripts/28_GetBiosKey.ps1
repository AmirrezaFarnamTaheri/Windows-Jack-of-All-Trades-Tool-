Write-Host "--- Retrieving OEM BIOS Windows Key ---" -ForegroundColor Cyan

$key = (Get-WmiObject -query 'select * from SoftwareLicensingService').OA3xOriginalProductKey

if ($key) {
    Write-Host "BIOS Product Key: $key" -ForegroundColor Green
} else {
    Write-Host "No OEM Key found in BIOS (Retail license used?)." -ForegroundColor Yellow
}