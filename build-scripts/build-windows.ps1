# FreeTDS Windows Build Script (x64 Release and Debug)
# Prerequisites:
#   - Visual Studio 2019 or 2022 with C++ workload
#   - CMake (included with Visual Studio or installed separately)
#   - OpenSSL for Windows (optional, will be auto-detected)
#   - Git
#
# Usage: .\build-windows.ps1 [-VSVersion "2022"] [-OpenSSLPath "C:\path\to\openssl"]

param(
    [string]$VSVersion = "2022",
    [string]$OpenSSLPath = "",
    [string]$SourceDir = "",
    [switch]$SkipPatch = $false,
    [switch]$CleanBuild = $false
)

$ErrorActionPreference = "Stop"

# Determine script and source directories
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if ([string]::IsNullOrEmpty($SourceDir)) {
    $SourceDir = Split-Path -Parent $ScriptDir
}

$BuildDirRelease = Join-Path $SourceDir "build-x64-release"
$BuildDirDebug = Join-Path $SourceDir "build-x64-debug"
$OutputDir = Join-Path $SourceDir "output"
$PatchFile = Join-Path $ScriptDir "freetds-sharedlib.patch"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "FreeTDS Windows Build (x64)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Source Directory: $SourceDir"
Write-Host "Visual Studio Version: $VSVersion"
Write-Host ""

# Determine Visual Studio generator
switch ($VSVersion) {
    "2022" { $Generator = "Visual Studio 17 2022" }
    "2019" { $Generator = "Visual Studio 16 2019" }
    "2017" { $Generator = "Visual Studio 15 2017" }
    default { 
        Write-Error "Unsupported Visual Studio version: $VSVersion. Use 2017, 2019, or 2022."
        exit 1
    }
}

# Check if CMake is available
$cmake = Get-Command cmake -ErrorAction SilentlyContinue
if (-not $cmake) {
    Write-Error "CMake not found. Please install CMake or add it to PATH."
    exit 1
}
Write-Host "Using CMake: $($cmake.Source)"

# Check if MSBuild is available
$msbuild = Get-Command msbuild -ErrorAction SilentlyContinue
if (-not $msbuild) {
    # Try to find MSBuild in common locations
    $msbuildPaths = @(
        "C:\Program Files\Microsoft Visual Studio\$VSVersion\Community\MSBuild\Current\Bin\MSBuild.exe",
        "C:\Program Files\Microsoft Visual Studio\$VSVersion\Professional\MSBuild\Current\Bin\MSBuild.exe",
        "C:\Program Files\Microsoft Visual Studio\$VSVersion\Enterprise\MSBuild\Current\Bin\MSBuild.exe",
        "C:\Program Files (x86)\Microsoft Visual Studio\$VSVersion\BuildTools\MSBuild\Current\Bin\MSBuild.exe"
    )
    foreach ($path in $msbuildPaths) {
        if (Test-Path $path) {
            $msbuild = $path
            break
        }
    }
    if (-not $msbuild) {
        Write-Error "MSBuild not found. Please run from Developer Command Prompt or install Build Tools."
        exit 1
    }
}
Write-Host "Using MSBuild: $msbuild"

# Clean build directories if requested
if ($CleanBuild) {
    Write-Host "Cleaning build directories..." -ForegroundColor Yellow
    if (Test-Path $BuildDirRelease) { Remove-Item -Recurse -Force $BuildDirRelease }
    if (Test-Path $BuildDirDebug) { Remove-Item -Recurse -Force $BuildDirDebug }
    if (Test-Path $OutputDir) { Remove-Item -Recurse -Force $OutputDir }
}

# Create build directories
New-Item -ItemType Directory -Force -Path $BuildDirRelease | Out-Null
New-Item -ItemType Directory -Force -Path $BuildDirDebug | Out-Null
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $OutputDir "include") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $OutputDir "include\freetds") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $OutputDir "lib\x64\Release") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $OutputDir "lib\x64\Debug") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $OutputDir "bin\x64\Release") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $OutputDir "bin\x64\Debug") | Out-Null

# Build CMake options
$CMakeOptions = @(
    "-G", "`"$Generator`"",
    "-A", "x64",
    "-DWITH_OPENSSL=ON",
    "-DBUILD_SHARED_LIB=ON"
)

if (-not [string]::IsNullOrEmpty($OpenSSLPath)) {
    $CMakeOptions += "-DOPENSSL_ROOT_DIR=`"$OpenSSLPath`""
}

# Configure and build Release
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Configuring Release build..." -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Push-Location $BuildDirRelease
$cmakeCmd = "cmake $($CMakeOptions -join ' ') `"$SourceDir`""
Write-Host "Running: $cmakeCmd"
Invoke-Expression $cmakeCmd
if ($LASTEXITCODE -ne 0) {
    Pop-Location
    Write-Error "CMake configuration failed for Release build."
    exit 1
}

Write-Host ""
Write-Host "Building Release..." -ForegroundColor Green
& $msbuild FreeTDS.sln /p:Configuration=Release /p:Platform=x64 /m /v:minimal
if ($LASTEXITCODE -ne 0) {
    Pop-Location
    Write-Error "Release build failed."
    exit 1
}
Pop-Location

# Configure and build Debug
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Configuring Debug build..." -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Push-Location $BuildDirDebug
$cmakeCmd = "cmake $($CMakeOptions -join ' ') `"$SourceDir`""
Write-Host "Running: $cmakeCmd"
Invoke-Expression $cmakeCmd
if ($LASTEXITCODE -ne 0) {
    Pop-Location
    Write-Error "CMake configuration failed for Debug build."
    exit 1
}

Write-Host ""
Write-Host "Building Debug..." -ForegroundColor Green
& $msbuild FreeTDS.sln /p:Configuration=Debug /p:Platform=x64 /m /v:minimal
if ($LASTEXITCODE -ne 0) {
    Pop-Location
    Write-Error "Debug build failed."
    exit 1
}
Pop-Location

# Copy output files
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Copying output files..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Copy headers from source include directory
$SourceHeaders = @(
    "bkpublic.h",
    "cspublic.h",
    "cstypes.h",
    "ctpublic.h",
    "sqldb.h",
    "sqlfront.h",
    "sybdb.h",
    "sybfront.h",
    "syberror.h"
)

foreach ($header in $SourceHeaders) {
    $src = Join-Path $SourceDir "include\$header"
    if (Test-Path $src) {
        Copy-Item $src (Join-Path $OutputDir "include\$header") -Force
    }
}

# Copy freetds subdirectory headers
$FreeTDSHeaders = @(
    "export.h",
    "server.h",
    "tds.h",
    "proto.h",
    "bytes.h",
    "configs.h",
    "convert.h",
    "data.h",
    "encodings.h",
    "iconv.h",
    "macros.h",
    "stream.h",
    "tls.h",
    "bool.h",
    "alloca.h",
    "pushvis.h",
    "popvis.h",
    "thread.h",
    "time.h",
    "checks.h",
    "unused.h",
    "version.h",
    "sysdep_types.h"
)

$freetdsIncludeDir = Join-Path $SourceDir "include\freetds"
$freetdsOutputDir = Join-Path $OutputDir "include\freetds"

foreach ($header in $FreeTDSHeaders) {
    $src = Join-Path $freetdsIncludeDir $header
    if (Test-Path $src) {
        Copy-Item $src (Join-Path $freetdsOutputDir $header) -Force
    }
}

# Copy generated headers from build directory
$GeneratedHeaders = @(
    @{ Src = "include\config.h"; Dest = "include\config.h" },
    @{ Src = "include\tds_sysdep_public.h"; Dest = "include\tds_sysdep_public.h" },
    @{ Src = "include\freetds\version.h"; Dest = "include\freetds\version.h" },
    @{ Src = "include\freetds\sysdep_types.h"; Dest = "include\freetds\sysdep_types.h" }
)

foreach ($header in $GeneratedHeaders) {
    $src = Join-Path $BuildDirRelease $header.Src
    $dest = Join-Path $OutputDir $header.Dest
    if (Test-Path $src) {
        Copy-Item $src $dest -Force
    }
}

# Copy Release binaries
Write-Host "Copying Release binaries..."
$ReleaseFiles = @(
    @{ Pattern = "src\sharedlib\Release\freetds.dll"; Dest = "bin\x64\Release" },
    @{ Pattern = "src\sharedlib\Release\freetds.lib"; Dest = "lib\x64\Release" },
    @{ Pattern = "src\sharedlib\Release\freetds.pdb"; Dest = "bin\x64\Release" }
)

foreach ($file in $ReleaseFiles) {
    $src = Join-Path $BuildDirRelease $file.Pattern
    $dest = Join-Path $OutputDir $file.Dest
    if (Test-Path $src) {
        Copy-Item $src $dest -Force
        Write-Host "  Copied: $($file.Pattern)"
    }
}

# Copy Debug binaries
Write-Host "Copying Debug binaries..."
$DebugFiles = @(
    @{ Pattern = "src\sharedlib\Debug\freetds.dll"; Dest = "bin\x64\Debug" },
    @{ Pattern = "src\sharedlib\Debug\freetds.lib"; Dest = "lib\x64\Debug" },
    @{ Pattern = "src\sharedlib\Debug\freetds.pdb"; Dest = "bin\x64\Debug" },
    @{ Pattern = "src\sharedlib\Debug\freetds.ilk"; Dest = "bin\x64\Debug" }
)

foreach ($file in $DebugFiles) {
    $src = Join-Path $BuildDirRelease $file.Pattern
    $dest = Join-Path $OutputDir $file.Dest
    if (Test-Path $src) {
        Copy-Item $src $dest -Force
        Write-Host "  Copied: $($file.Pattern)"
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Build completed successfully!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Output directory: $OutputDir"
Write-Host ""
Write-Host "Structure:"
Write-Host "  output/"
Write-Host "    include/           - Header files"
Write-Host "    include/freetds/   - FreeTDS-specific headers"
Write-Host "    lib/x64/Release/   - Release import library (.lib)"
Write-Host "    lib/x64/Debug/     - Debug import library (.lib)"
Write-Host "    bin/x64/Release/   - Release DLL and PDB"
Write-Host "    bin/x64/Debug/     - Debug DLL, PDB, and ILK"
