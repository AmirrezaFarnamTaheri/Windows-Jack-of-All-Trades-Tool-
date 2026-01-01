. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Auditing Non-Microsoft Services"
Get-SystemSummary
Write-Section "Scan Results"

try {
    $services = Get-Service | Where-Object { $_.Status -eq 'Running' }
    $nonMsServices = @()

    foreach ($s in $services) {
        if ($s.DisplayName -notmatch "Microsoft" -and $s.DisplayName -notmatch "Windows") {
            $nonMsServices += [PSCustomObject]@{
                Name = $s.Name
                DisplayName = $s.DisplayName
                Status = "<span class='status-pass'>Running</span>"
                Type = $s.ServiceType
            }
        }
    }

    if ($nonMsServices.Count -gt 0) {
        $report = New-Report "Non-Microsoft Service Audit"
        $report | Add-ReportSection "Running Third-Party Services ($($nonMsServices.Count))" $nonMsServices "Table"

        $outFile = "$env:USERPROFILE\Desktop\ServiceAudit_$(Get-Date -Format 'yyyyMMdd_HHmm').html"
        $report | Export-Report-Html $outFile

        Show-Success "Found $($nonMsServices.Count) services. Report saved to $outFile"
        Invoke-Item $outFile
    } else {
        Show-Success "No obvious non-Microsoft services running."
    }
} catch {
    Show-Error "Error: $($_.Exception.Message)"
}
Pause-If-Interactive
