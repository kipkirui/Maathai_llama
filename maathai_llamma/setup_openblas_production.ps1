# OpenBLAS Production Setup Script
# Downloads and sets up OpenBLAS libraries for production build

param(
    [string]$OutputDir = ".\android\src\main\jniLibs"
)

Write-Host "========================================" -ForegroundColor Green
Write-Host "OpenBLAS Production Setup" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

# Create output directories
$Arm64Dir = Join-Path $OutputDir "arm64-v8a"
$ArmV7Dir = Join-Path $OutputDir "armeabi-v7a"

New-Item -ItemType Directory -Path $Arm64Dir -Force | Out-Null
New-Item -ItemType Directory -Path $ArmV7Dir -Force | Out-Null

Write-Host "Setting up OpenBLAS libraries for production build..." -ForegroundColor Yellow
Write-Host ""

# For now, let's create a workaround by temporarily disabling OpenBLAS requirement
Write-Host "Option 1: Use the no-OpenBLAS build for now" -ForegroundColor Cyan
Write-Host "This will work but with reduced performance:" -ForegroundColor White
Write-Host ".\build_offline_no_openblas.ps1 -AndroidNdkPath `"C:\Users\$env:USERNAME\AppData\Local\Android\Sdk\ndk\27.0.12077973`"" -ForegroundColor Green
Write-Host ""

Write-Host "Option 2: Get OpenBLAS libraries" -ForegroundColor Cyan
Write-Host "1. Download from: https://github.com/xianyi/OpenBLAS/releases" -ForegroundColor White
Write-Host "2. Look for Android ARM builds or build from source" -ForegroundColor White
Write-Host "3. Place libopenblas.so in:" -ForegroundColor White
Write-Host "   - $Arm64Dir\libopenblas.so" -ForegroundColor White
Write-Host "   - $ArmV7Dir\libopenblas.so" -ForegroundColor White
Write-Host ""

Write-Host "Option 3: Quick test with stub libraries" -ForegroundColor Cyan
Write-Host "Creating minimal stub libraries for testing..." -ForegroundColor Yellow

# Create minimal stub libraries (these won't work for actual computation but allow the build to proceed)
$StubContent = @"
// Minimal OpenBLAS stub for testing
// This allows the build to proceed but provides no acceleration
// Replace with actual OpenBLAS library for production use

#include <stdio.h>

// Stub functions
void cblas_sgemm() { printf("OpenBLAS stub: cblas_sgemm\n"); }
void cblas_dgemm() { printf("OpenBLAS stub: cblas_dgemm\n"); }
void cblas_sgemv() { printf("OpenBLAS stub: cblas_sgemv\n"); }
void cblas_dgemv() { printf("OpenBLAS stub: cblas_dgemv\n"); }
"@

# Create stub source files
$StubSource = Join-Path $PSScriptRoot "openblas_stub.c"
$StubContent | Out-File -FilePath $StubSource -Encoding UTF8

Write-Host "Created stub source: $StubSource" -ForegroundColor Green
Write-Host ""

Write-Host "========================================" -ForegroundColor Green
Write-Host "Recommendation: Use Option 1 for now" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Green
Write-Host "The no-OpenBLAS build will work and you can add OpenBLAS later" -ForegroundColor White
Write-Host "for better performance. This allows you to test the plugin immediately." -ForegroundColor White
Write-Host ""
Write-Host "Run this command to build without OpenBLAS:" -ForegroundColor Cyan
Write-Host ".\build_offline_no_openblas.ps1 -AndroidNdkPath `"C:\Users\$env:USERNAME\AppData\Local\Android\Sdk\ndk\27.0.12077973`"" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
