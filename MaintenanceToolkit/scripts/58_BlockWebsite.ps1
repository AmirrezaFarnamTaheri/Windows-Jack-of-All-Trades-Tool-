. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Block Website (Hosts File)"
Get-SystemSummary
Write-Section "Input"

$domain = Read-Host "Enter domain to block (e.g. facebook.com)"

try {
    # Basic domain regex validation
    if ($domain -match '^([a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,6}$') {
        $hosts = "$env:WINDIR\System32\drivers\etc\hosts"

        if (-not (Test-Path $hosts)) {
            New-Item -Path $hosts -ItemType File -Force | Out-Null
        }

        if (Select-String -Path $hosts -Pattern $domain -Quiet) {
            Show-Error "Domain already blocked."
        } else {
            Write-Section "Blocking"
            Add-Content -Path $hosts -Value "127.0.0.1 $domain"
            Add-Content -Path $hosts -Value "127.0.0.1 www.$domain"
            ipconfig /flushdns | Out-Null
            Show-Success "Blocked $domain and flushed DNS."
        }
    } else {
        Show-Error "Invalid domain format."
    }
} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
