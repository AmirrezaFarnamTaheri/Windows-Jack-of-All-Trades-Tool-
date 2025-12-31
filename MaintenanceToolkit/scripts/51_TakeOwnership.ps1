. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Take Ownership of File/Folder"
$target = Read-Host "Enter file or folder path"

try {
    if (Test-Path $target) {
        Write-Log "Taking ownership..."
        takeown /f "$target" /r /d y
        Write-Log "Granting permissions..."
        icacls "$target" /grant Administrators:F /t
        Write-Log "Ownership taken." "Green"
    } else {
        Write-Log "Path not found." "Red"
    }
} catch {
    Write-Log "Error: $($_.Exception.Message)" "Red"
}
Pause-If-Interactive
