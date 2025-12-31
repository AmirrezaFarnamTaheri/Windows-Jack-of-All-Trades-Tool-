Write-Host "--- Building System Maintenance GUI ---" -ForegroundColor Cyan

# Define filenames
$SourceFile = ".\source\MaintenanceTool.cs"
$OutputFile = ".\MaintenanceTool.exe"
$ManifestFile = ".\app.manifest"

# Check if source exists
if (-not (Test-Path $SourceFile)) {
    Write-Host "Error: Could not find $SourceFile" -ForegroundColor Red
    Pause
    Exit
}

# Find the C# Compiler (csc.exe)
$CSC = Get-ChildItem -Path "$env:windir\Microsoft.NET\Framework64\v4*" -Filter "csc.exe" -Recurse | Select-Object -Last 1

if (-not $CSC) {
    Write-Host "Error: Could not find C# Compiler." -ForegroundColor Red
    Pause
    Exit
}

Write-Host "Using Compiler: $($CSC.FullName)" -ForegroundColor DarkGray

# Compile Command
# We link Windows Forms, Drawing, System.Management (for WMI checks), and the Manifest
$BuildCmd = "& '$($CSC.FullName)' /target:winexe /out:'$OutputFile' /win32manifest:'$ManifestFile' /r:System.Windows.Forms.dll /r:System.Drawing.dll /r:System.Management.dll '$SourceFile'"

Invoke-Expression $BuildCmd

if (Test-Path $OutputFile) {
    Write-Host "`nSUCCESS! Application created: $OutputFile" -ForegroundColor Green
    Write-Host "You can now delete the .cs and .ps1 files if you want." -ForegroundColor Yellow
    Write-Host "Remember to Right-Click > Run as Administrator" -ForegroundColor Magenta
} else {
    Write-Host "Compilation Failed." -ForegroundColor Red
}

Pause
