# OpenBLAS Download Script for Maathai Llamma
# Downloads prebuilt OpenBLAS libraries for Android ARM architectures

param(
    [string]$OutputDir = ".\maathai_llamma\android\src\main\jniLibs",
    [string]$OpenBlasVersion = "0.3.25"
)

Write-Host "========================================" -ForegroundColor Green
Write-Host "OpenBLAS Download Script" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "Downloading OpenBLAS version: $OpenBlasVersion"
Write-Host "Output directory: $OutputDir"
Write-Host "========================================" -ForegroundColor Green

# Create output directories
$Arm64Dir = Join-Path $OutputDir "arm64-v8a"
$ArmV7Dir = Join-Path $OutputDir "armeabi-v7a"

if (-not (Test-Path $Arm64Dir)) {
    New-Item -ItemType Directory -Path $Arm64Dir -Force | Out-Null
}
if (-not (Test-Path $ArmV7Dir)) {
    New-Item -ItemType Directory -Path $ArmV7Dir -Force | Out-Null
}

# URLs for OpenBLAS Android builds (these may need to be updated)
$OpenBlasUrls = @{
    "arm64-v8a" = "https://github.com/xianyi/OpenBLAS/releases/download/v$OpenBlasVersion/OpenBLAS-$OpenBlasVersion-android-arm64.tar.gz"
    "armeabi-v7a" = "https://github.com/xianyi/OpenBLAS/releases/download/v$OpenBlasVersion/OpenBLAS-$OpenBlasVersion-android-armv7.tar.gz"
}

# Alternative: Use a more reliable source or provide manual download instructions
Write-Host ""
Write-Host "IMPORTANT: OpenBLAS Android builds may not be directly available from GitHub releases." -ForegroundColor Yellow
Write-Host "You have several options:" -ForegroundColor Yellow
Write-Host ""
Write-Host "Option 1: Build OpenBLAS from source for Android" -ForegroundColor Cyan
Write-Host "  - Clone: git clone https://github.com/xianyi/OpenBLAS.git"
Write-Host "  - Follow Android build instructions in the repository"
Write-Host ""
Write-Host "Option 2: Use prebuilt libraries from a trusted source" -ForegroundColor Cyan
Write-Host "  - Search for 'OpenBLAS Android ARM' on GitHub"
Write-Host "  - Look for repositories that provide prebuilt Android libraries"
Write-Host ""
Write-Host "Option 3: Use a different BLAS library" -ForegroundColor Cyan
Write-Host "  - Consider using Eigen or other lightweight alternatives"
Write-Host "  - Modify CMakeLists.txt accordingly"
Write-Host ""

# Create a helper script for manual setup
$HelperScript = @"
# Manual OpenBLAS Setup Instructions
# =================================

# 1. Download OpenBLAS source
git clone https://github.com/xianyi/OpenBLAS.git
cd OpenBLAS

# 2. Build for Android ARM64
mkdir build-arm64
cd build-arm64
cmake .. \
  -DCMAKE_TOOLCHAIN_FILE=`$ANDROID_NDK/build/cmake/android.toolchain.cmake \
  -DANDROID_ABI=arm64-v8a \
  -DANDROID_PLATFORM=android-21 \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=ON
make -j4

# 3. Build for Android ARMv7
cd ..
mkdir build-armv7
cd build-armv7
cmake .. \
  -DCMAKE_TOOLCHAIN_FILE=`$ANDROID_NDK/build/cmake/android.toolchain.cmake \
  -DANDROID_ABI=armeabi-v7a \
  -DANDROID_PLATFORM=android-21 \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=ON
make -j4

# 4. Copy libraries
cp build-arm64/libopenblas.so $Arm64Dir/
cp build-armv7/libopenblas.so $ArmV7Dir/

# 5. Verify files exist
ls -la $Arm64Dir/libopenblas.so
ls -la $ArmV7Dir/libopenblas.so
"@

$HelperScript | Out-File -FilePath ".\maathai_llamma\setup_openblas_manual.sh" -Encoding UTF8

Write-Host "Created manual setup script: .\maathai_llamma\setup_openblas_manual.sh" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Follow the manual setup instructions above"
Write-Host "2. Or find prebuilt OpenBLAS libraries for Android"
Write-Host "3. Place libopenblas.so in the appropriate jniLibs directories"
Write-Host "4. Run the build script: .\maathai_llamma\build_offline.ps1"
Write-Host ""
Write-Host "Expected file structure:" -ForegroundColor Cyan
Write-Host "  $Arm64Dir\libopenblas.so"
Write-Host "  $ArmV7Dir\libopenblas.so"
Write-Host "========================================" -ForegroundColor Green
