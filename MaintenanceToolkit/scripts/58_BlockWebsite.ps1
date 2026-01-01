. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Block Website (Hosts File)"
Get-SystemSummary
Write-Section "Input"

$domain = Read-Host "Enter domain to block (e.g. facebook.com)"

try {
    if (-not [string]::IsNullOrWhiteSpace($domain)) {
        $hosts = "$env:WINDIR\System32\drivers\etc\hosts"

        if (Select-String -Path $hosts -Pattern $domain -Quiet) {
            Show-Error "Domain already blocked."
        } else {
            Write-Section "Blocking"
            Add-Content -Path $hosts -Value "127.0.0.1 $domain"
            Add-Content -Path $hosts -Value "127.0.0.1 www.$domain"
            Show-Success "Blocked $domain."
        }
    } else {
        Show-Error "Invalid domain."
    }
} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
