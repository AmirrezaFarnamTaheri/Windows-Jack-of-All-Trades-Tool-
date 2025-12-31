. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Auditing Non-Microsoft Services"

$services = Get-WmiObject Win32_Service | Where-Object {
    $_.State -eq 'Running' -and
    $_.DisplayName -notmatch "Microsoft" -and
    $_.DisplayName -notmatch "Windows" -and
    $_.DisplayName -notmatch "Intel" -and
    $_.DisplayName -notmatch "AMD"
} | Select-Object DisplayName, Name, StartMode, PathName

if ($services) {
    $services | Format-Table -AutoSize
    Write-Host "Review the list above. If you don't recognize it, Google it." -ForegroundColor Yellow
} else {
    Write-Host "No obvious 3rd party services running." -ForegroundColor Green
}