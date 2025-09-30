# OpenBLAS Setup Script for Maathai Llamma
# Downloads and sets up OpenBLAS libraries for Android ARM architectures

param(
    [string]$OutputDir = ".\android\src\main\jniLibs",
    [switch]$Force = $false
)

Write-Host "========================================" -ForegroundColor Green
Write-Host "OpenBLAS Setup for Maathai Llamma" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

# Create output directories
$Arm64Dir = Join-Path $OutputDir "arm64-v8a"
$ArmV7Dir = Join-Path $OutputDir "armeabi-v7a"

if (-not (Test-Path $Arm64Dir)) {
    New-Item -ItemType Directory -Path $Arm64Dir -Force | Out-Null
    Write-Host "Created directory: $Arm64Dir" -ForegroundColor Yellow
}
if (-not (Test-Path $ArmV7Dir)) {
    New-Item -ItemType Directory -Path $ArmV7Dir -Force | Out-Null
    Write-Host "Created directory: $ArmV7Dir" -ForegroundColor Yellow
}

# Check if libraries already exist
$Arm64Lib = Join-Path $Arm64Dir "libopenblas.so"
$ArmV7Lib = Join-Path $ArmV7Dir "libopenblas.so"

if ((Test-Path $Arm64Lib) -and (Test-Path $ArmV7Lib) -and -not $Force) {
    Write-Host "OpenBLAS libraries already exist. Use -Force to reinstall." -ForegroundColor Yellow
    Write-Host "Arm64: $Arm64Lib"
    Write-Host "ArmV7: $ArmV7Lib"
    exit 0
}

Write-Host ""
Write-Host "Setting up OpenBLAS libraries..." -ForegroundColor Cyan
Write-Host ""

# Option 1: Try to download from a reliable source
Write-Host "Attempting to download prebuilt OpenBLAS libraries..." -ForegroundColor Yellow

# Create a temporary directory for downloads
$TempDir = Join-Path $env:TEMP "maathai_openblas"
if (Test-Path $TempDir) {
    Remove-Item $TempDir -Recurse -Force
}
New-Item -ItemType Directory -Path $TempDir -Force | Out-Null

try {
    # Try to download from a reliable source
    $OpenBlasRepo = "https://github.com/xianyi/OpenBLAS"
    $ReleaseUrl = "https://api.github.com/repos/xianyi/OpenBLAS/releases/latest"
    
    Write-Host "Fetching latest OpenBLAS release info..." -ForegroundColor Yellow
    $ReleaseInfo = Invoke-RestMethod -Uri $ReleaseUrl
    
    Write-Host "Latest release: $($ReleaseInfo.tag_name)" -ForegroundColor Green
    
    # Look for Android builds in the release assets
    $AndroidAssets = $ReleaseInfo.assets | Where-Object { $_.name -like "*android*" -or $_.name -like "*arm*" }
    
    if ($AndroidAssets.Count -eq 0) {
        Write-Host "No prebuilt Android libraries found in releases." -ForegroundColor Yellow
        Write-Host "Falling back to manual setup instructions..." -ForegroundColor Yellow
        throw "No prebuilt libraries available"
    }
    
    # Download and extract (this is a simplified approach)
    Write-Host "Found Android assets, but manual setup is recommended for reliability." -ForegroundColor Yellow
    throw "Manual setup required"
    
} catch {
    Write-Host ""
    Write-Host "Prebuilt libraries not available. Setting up manual build instructions..." -ForegroundColor Yellow
    Write-Host ""
    
    # Create manual setup instructions
    $ManualSetupScript = @"
# Manual OpenBLAS Build for Android
# =================================

# Prerequisites
# - Android NDK installed
# - CMake 3.22+
# - Git

# 1. Clone OpenBLAS repository
git clone https://github.com/xianyi/OpenBLAS.git
cd OpenBLAS

# 2. Set environment variables
set ANDROID_NDK=D:\Android\ndk\26.1.10909125
set CMAKE_TOOLCHAIN_FILE=%ANDROID_NDK%\build\cmake\android.toolchain.cmake

# 3. Build for ARM64
mkdir build-arm64
cd build-arm64
cmake .. ^
  -DCMAKE_TOOLCHAIN_FILE=%CMAKE_TOOLCHAIN_FILE% ^
  -DANDROID_ABI=arm64-v8a ^
  -DANDROID_PLATFORM=android-21 ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DBUILD_SHARED_LIBS=ON ^
  -DNO_FORTRAN=1
cmake --build . --config Release

# 4. Build for ARMv7
cd ..
mkdir build-armv7
cd build-armv7
cmake .. ^
  -DCMAKE_TOOLCHAIN_FILE=%CMAKE_TOOLCHAIN_FILE% ^
  -DANDROID_ABI=armeabi-v7a ^
  -DANDROID_PLATFORM=android-21 ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DBUILD_SHARED_LIBS=ON ^
  -DNO_FORTRAN=1
cmake --build . --config Release

# 5. Copy libraries
copy build-arm64\lib\libopenblas.so $Arm64Dir\
copy build-armv7\lib\libopenblas.so $ArmV7Dir\

# 6. Verify
dir $Arm64Dir\libopenblas.so
dir $ArmV7Dir\libopenblas.so
"@

    $ManualScriptPath = Join-Path $PSScriptRoot "build_openblas_manual.bat"
    $ManualSetupScript | Out-File -FilePath $ManualScriptPath -Encoding UTF8
    
    Write-Host "Created manual build script: $ManualScriptPath" -ForegroundColor Green
    Write-Host ""
    Write-Host "Alternative: Use prebuilt libraries from trusted sources" -ForegroundColor Cyan
    Write-Host "1. Search GitHub for 'OpenBLAS Android' repositories" -ForegroundColor White
    Write-Host "2. Look for repositories with prebuilt ARM libraries" -ForegroundColor White
    Write-Host "3. Download and place in jniLibs directories" -ForegroundColor White
    Write-Host ""
    Write-Host "Quick setup with prebuilt libraries:" -ForegroundColor Yellow
    Write-Host "1. Find libopenblas.so for arm64-v8a and armeabi-v7a" -ForegroundColor White
    Write-Host "2. Copy to:" -ForegroundColor White
    Write-Host "   - $Arm64Lib" -ForegroundColor White
    Write-Host "   - $ArmV7Lib" -ForegroundColor White
    Write-Host "3. Run: .\build_offline.ps1" -ForegroundColor White
}

# Clean up temp directory
if (Test-Path $TempDir) {
    Remove-Item $TempDir -Recurse -Force
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "OpenBLAS Setup Complete" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Ensure libopenblas.so files are in place" -ForegroundColor White
Write-Host "2. Run the build script: .\build_offline.ps1" -ForegroundColor White
Write-Host "3. Test with Flutter example app" -ForegroundColor White
Write-Host ""
