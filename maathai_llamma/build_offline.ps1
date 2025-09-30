# Maathai Llamma Offline Build Script for Android
# This script builds the native library completely offline using CMake and Ninja

param(
    [string]$AndroidNdkPath = "D:\Android\ndk\26.1.10909125",
    [string]$BuildType = "Release"
)

Write-Host "========================================" -ForegroundColor Green
Write-Host "Maathai Llamma Offline Build Script" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

# Configuration - Use system CMake and Ninja
$CmakePath = "cmake"  # Use system CMake from PATH
$NinjaPath = "ninja"  # Use system Ninja from PATH
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$PluginRoot = Join-Path $ProjectRoot "maathai_llamma"
$ExternRoot = Join-Path $PluginRoot "extern\llama.cpp"

# Check if NDK exists
if (-not (Test-Path $AndroidNdkPath)) {
    Write-Error "Android NDK not found at $AndroidNdkPath"
    Write-Host "Please update the AndroidNdkPath parameter or set it correctly"
    exit 1
}

# Check if CMake and Ninja exist in PATH
$CmakeCheck = Get-Command $CmakePath -ErrorAction SilentlyContinue
if (-not $CmakeCheck) {
    Write-Error "CMake not found in PATH. Please install CMake and add it to your PATH."
    exit 1
}

$NinjaCheck = Get-Command $NinjaPath -ErrorAction SilentlyContinue
if (-not $NinjaCheck) {
    Write-Error "Ninja not found in PATH. Please install Ninja and add it to your PATH."
    exit 1
}

Write-Host "NDK Path: $AndroidNdkPath"
Write-Host "CMake Path: $CmakePath"
Write-Host "Ninja Path: $NinjaPath"
Write-Host "Build Type: $BuildType"
Write-Host "========================================" -ForegroundColor Green

# Build for both architectures
$ABIs = @("arm64-v8a", "armeabi-v7a")

foreach ($ABI in $ABIs) {
    Write-Host ""
    Write-Host "Building for $ABI..." -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow
    
    $BuildDir = Join-Path $PluginRoot "build\$ABI"
    $JniLibsDir = Join-Path $PluginRoot "android\src\main\jniLibs\$ABI"
    
    # Create build directory
    if (-not (Test-Path $BuildDir)) {
        New-Item -ItemType Directory -Path $BuildDir -Force | Out-Null
    }
    
    # Check if OpenBLAS library exists
    $OpenBlasLib = Join-Path $JniLibsDir "libopenblas.so"
    if (-not (Test-Path $OpenBlasLib)) {
        Write-Error "OpenBLAS library not found at $OpenBlasLib"
        Write-Host "Please download and place libopenblas.so for $ABI architecture"
        Write-Host "Download from: https://github.com/xianyi/OpenBLAS/releases"
        Write-Host "Or build from source for Android"
        Write-Host ""
        Write-Host "For now, you can use the no-OpenBLAS build:"
        Write-Host ".\build_offline_no_openblas.ps1 -AndroidNdkPath `"$AndroidNdkPath`""
        exit 1
    }
    
    # Configure with CMake
    Write-Host "Configuring CMake for $ABI..."
    $CmakeArgs = @(
        "-S", (Join-Path $PluginRoot "android\src\main\cpp")
        "-B", $BuildDir
        "-DCMAKE_TOOLCHAIN_FILE=$(Join-Path $AndroidNdkPath 'build\cmake\android.toolchain.cmake')"
        "-DANDROID_ABI=$ABI"
        "-DANDROID_PLATFORM=android-21"
        "-DCMAKE_BUILD_TYPE=$BuildType"
        "-DCMAKE_MAKE_PROGRAM=$NinjaPath"
        "-G", "Ninja"
    )
    
    $ConfigureResult = & $CmakePath $CmakeArgs
    if ($LASTEXITCODE -ne 0) {
        Write-Error "CMake configuration failed for $ABI"
        Write-Host $ConfigureResult
        exit 1
    }
    
    # Build with Ninja
    Write-Host "Building with Ninja for $ABI..."
    $BuildArgs = @("--build", $BuildDir, "--target", "maathai_llamma")
    $BuildResult = & $CmakePath $BuildArgs
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Build failed for $ABI"
        Write-Host $BuildResult
        exit 1
    }
    
    # Copy the built library to jniLibs
    $OutputLib = Join-Path $BuildDir "maathai_llamma\libmaathai_llamma.so"
    if (Test-Path $OutputLib) {
        Write-Host "Copying libmaathai_llamma.so to jniLibs..."
        Copy-Item $OutputLib $JniLibsDir -Force
        Write-Host "Successfully built and copied libmaathai_llamma.so for $ABI" -ForegroundColor Green
    } else {
        Write-Error "Output library not found at $OutputLib"
        exit 1
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Build completed successfully!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "Native libraries have been built and copied to:"
Write-Host "  - $(Join-Path $PluginRoot 'android\src\main\jniLibs\arm64-v8a\libmaathai_llamma.so')"
Write-Host "  - $(Join-Path $PluginRoot 'android\src\main\jniLibs\armeabi-v7a\libmaathai_llamma.so')"
Write-Host ""
Write-Host "You can now:"
Write-Host "1. Build the Flutter plugin: flutter build aar"
Write-Host "2. Run the example app: flutter run -d device"
Write-Host "3. Check logs with: adb logcat | findstr 'MaathaiLL-NATIVE'"
Write-Host "========================================" -ForegroundColor Green