param(
    [switch]$Test
)

Write-Host "--- Building System Maintenance GUI (v3.0) ---" -ForegroundColor Cyan

# Define paths
$SourceDir = Join-Path $PSScriptRoot "source"
$OutputFile = Join-Path $PSScriptRoot "MaintenanceTool.exe"
$TestFile = Join-Path $PSScriptRoot "RunTests.exe"
$ManifestFile = Join-Path $PSScriptRoot "app.manifest"

# Find C# Sources (Recursively)
$SourceFiles = Get-ChildItem -Path $SourceDir -Filter "*.cs" -Recurse | Select-Object -ExpandProperty FullName

# Filter out Test files for main build
$AppFiles = $SourceFiles | Where-Object { $_ -notmatch "TestRunner.cs" -and $_ -notmatch "Tests" }

if ($AppFiles.Count -eq 0) {
    Write-Host "Error: No .cs files found in $SourceDir" -ForegroundColor Red
    if (-not [Console]::IsInputRedirected) { Pause }
    Exit
}

Write-Host "Found $($AppFiles.Count) source files." -ForegroundColor Gray

# Find Compiler
$CSC = Get-ChildItem -Path "$env:windir\Microsoft.NET\Framework64\v4*" -Filter "csc.exe" -Recurse | Select-Object -Last 1

if (-not $CSC) {
    Write-Host "Error: Could not find C# Compiler (CSC.exe)." -ForegroundColor Red
    if (-not [Console]::IsInputRedirected) { Pause }
    Exit
}

Write-Host "Using Compiler: $($CSC.FullName)" -ForegroundColor DarkGray

# --- Build Application ---
$BuildArgs = @(
    "/target:winexe",
    "/out:$OutputFile",
    "/win32manifest:$ManifestFile",
    "/r:System.Windows.Forms.dll",
    "/r:System.Drawing.dll",
    "/r:System.Management.dll",
    "/r:System.dll",
    "/r:System.Core.dll",
    "/r:System.Data.dll",
    "/r:System.Xml.dll",
    "/r:System.Xml.Linq.dll"
)

# Embed Scripts
$ScriptDir = Join-Path $PSScriptRoot "scripts"
if (Test-Path $ScriptDir) {
    Get-ChildItem -Path $ScriptDir -Recurse -File | ForEach-Object {
        $RelPath = $_.FullName.Substring($ScriptDir.Length + 1).Replace("\", "/")
        $ResName = "scripts/$RelPath"
        $BuildArgs += "/resource:`"$($_.FullName)`",$ResName"
    }
    Write-Host "Embedded $( (Get-ChildItem $ScriptDir -Recurse -File).Count ) scripts." -ForegroundColor Gray
}

# Embed Help
$HelpFile = Join-Path $PSScriptRoot "HELP.md"
if (Test-Path $HelpFile) {
    $BuildArgs += "/resource:`"$HelpFile`",HELP.md"
}

# Add Files
foreach ($file in $AppFiles) { $BuildArgs += "`"$file`"" }

Write-Host "Compiling Application..." -ForegroundColor Cyan
try {
    $p = Start-Process -FilePath $CSC.FullName -ArgumentList $BuildArgs -PassThru -NoNewWindow -Wait
    if ($p.ExitCode -eq 0 -and (Test-Path $OutputFile)) {
        Write-Host "SUCCESS! Created: $OutputFile" -ForegroundColor Green
    } else {
        Write-Host "Compilation Failed. Exit Code: $($p.ExitCode)" -ForegroundColor Red
        Exit
    }
} catch {
    Write-Host "Error executing compiler: $_" -ForegroundColor Red
}

# --- Build Tests ---
if ($Test) {
    Write-Host "`n--- Building Tests ---" -ForegroundColor Cyan
    $TestArgs = @(
        "/target:exe",
        "/out:$TestFile",
        "/r:System.Windows.Forms.dll",
        "/r:System.Drawing.dll",
        "/r:System.Management.dll",
        "/r:System.dll",
        "/r:System.Core.dll"
    )

    # We need App Files (except Program.cs/MainForm.cs? No, we need Core logic)
    # Actually we just include everything EXCEPT Program.cs (entry point conflict) and MainForm (UI dependency, tough to test in unit test)
    # Ideally we'd move Core to a DLL, but for single-file simplicity we just include source files.

    $TestSources = $SourceFiles | Where-Object {
        $_ -notmatch "Program.cs" -and
        $_ -notmatch "MainForm.cs" -and
        $_ -notmatch "ToastOverlay.cs" -and
        $_ -notmatch "ScriptCard.cs" -and
        $_ -notmatch "Widgets"
    }

    foreach ($file in $TestSources) { $TestArgs += "`"$file`"" }

    try {
        $p = Start-Process -FilePath $CSC.FullName -ArgumentList $TestArgs -PassThru -NoNewWindow -Wait
        if ($p.ExitCode -eq 0) {
            Write-Host "Running Tests..." -ForegroundColor Cyan
            & $TestFile
            if ($LASTEXITCODE -eq 0) {
                Write-Host "ALL TESTS PASSED" -ForegroundColor Green
            } else {
                Write-Host "TESTS FAILED" -ForegroundColor Red
            }
            Remove-Item $TestFile -ErrorAction SilentlyContinue
        } else {
            Write-Host "Test Compilation Failed." -ForegroundColor Red
        }
    } catch {
        Write-Host "Error building tests: $_" -ForegroundColor Red
    }
}

if (-not [Console]::IsInputRedirected) { Pause }
