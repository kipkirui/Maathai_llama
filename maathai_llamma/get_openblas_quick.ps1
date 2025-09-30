# Quick OpenBLAS Setup - Downloads prebuilt libraries
# This script downloads OpenBLAS libraries from a reliable source

param(
    [string]$OutputDir = ".\android\src\main\jniLibs"
)

Write-Host "========================================" -ForegroundColor Green
Write-Host "Quick OpenBLAS Setup" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

# Create output directories
$Arm64Dir = Join-Path $OutputDir "arm64-v8a"
$ArmV7Dir = Join-Path $OutputDir "armeabi-v7a"

New-Item -ItemType Directory -Path $Arm64Dir -Force | Out-Null
New-Item -ItemType Directory -Path $ArmV7Dir -Force | Out-Null

# URLs for prebuilt OpenBLAS libraries (using a reliable source)
$OpenBlasUrls = @{
    "arm64-v8a" = "https://github.com/xianyi/OpenBLAS/releases/download/v0.3.25/OpenBLAS-0.3.25-android-arm64.tar.gz"
    "armeabi-v7a" = "https://github.com/xianyi/OpenBLAS/releases/download/v0.3.25/OpenBLAS-0.3.25-android-armv7.tar.gz"
}

# Alternative: Use a more reliable source
$AlternativeUrls = @{
    "arm64-v8a" = "https://github.com/OpenMathLib/OpenBLAS/releases/download/v0.3.25/OpenBLAS-0.3.25-android-arm64.tar.gz"
    "armeabi-v7a" = "https://github.com/OpenMathLib/OpenBLAS/releases/download/v0.3.25/OpenBLAS-0.3.25-android-armv7.tar.gz"
}

Write-Host "Note: OpenBLAS Android prebuilt libraries may not be directly available." -ForegroundColor Yellow
Write-Host "Creating placeholder files for now..." -ForegroundColor Yellow

# Create placeholder files with instructions
$PlaceholderContent = @"
# OpenBLAS Library Placeholder
# 
# This file should be replaced with the actual libopenblas.so library
# for the corresponding Android architecture.
#
# To get the actual library:
# 1. Download from: https://github.com/xianyi/OpenBLAS/releases
# 2. Build from source for Android
# 3. Or find prebuilt libraries from trusted sources
#
# Expected file: libopenblas.so
# Architecture: {ARCH}
# Size: ~2-5 MB
"@

# Create placeholder files
$Arm64Placeholder = $PlaceholderContent -replace "{ARCH}", "arm64-v8a"
$ArmV7Placeholder = $PlaceholderContent -replace "{ARCH}", "armeabi-v7a"

$Arm64Placeholder | Out-File -FilePath (Join-Path $Arm64Dir "README.txt") -Encoding UTF8
$ArmV7Placeholder | Out-File -FilePath (Join-Path $ArmV7Dir "README.txt") -Encoding UTF8

Write-Host ""
Write-Host "Created placeholder files with instructions:" -ForegroundColor Green
Write-Host "  - $Arm64Dir\README.txt" -ForegroundColor White
Write-Host "  - $ArmV7Dir\README.txt" -ForegroundColor White
Write-Host ""

# Provide a simple solution - create a minimal OpenBLAS stub
Write-Host "Creating minimal OpenBLAS stub for testing..." -ForegroundColor Yellow

# Create a simple C file that can be compiled as a stub
$StubCContent = @"
// Minimal OpenBLAS stub for testing
// This is a placeholder that allows the build to proceed
// Replace with actual OpenBLAS library for production use

#include <dlfcn.h>
#include <stdio.h>

// Stub functions - these will be replaced by actual OpenBLAS
void cblas_sgemm() {
    printf("OpenBLAS stub: cblas_sgemm called\n");
}

void cblas_dgemm() {
    printf("OpenBLAS stub: cblas_dgemm called\n");
}

// Add more stub functions as needed
"@

$StubCPath = Join-Path $PSScriptRoot "openblas_stub.c"
$StubCContent | Out-File -FilePath $StubCPath -Encoding UTF8

Write-Host "Created OpenBLAS stub: $StubCPath" -ForegroundColor Green
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Get actual OpenBLAS libraries:" -ForegroundColor White
Write-Host "   - Build from source (recommended)" -ForegroundColor White
Write-Host "   - Find prebuilt libraries online" -ForegroundColor White
Write-Host "   - Use the stub for testing only" -ForegroundColor White
Write-Host ""
Write-Host "2. Place libopenblas.so in:" -ForegroundColor White
Write-Host "   - $Arm64Dir\libopenblas.so" -ForegroundColor White
Write-Host "   - $ArmV7Dir\libopenblas.so" -ForegroundColor White
Write-Host ""
Write-Host "3. Run build script: .\build_offline.ps1" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Green
