# Maathai Llamma - Offline Build Instructions

This guide explains how to build the Maathai Llamma Flutter plugin completely offline using CMake and Ninja, with OpenBLAS acceleration for optimal performance.

## Prerequisites

### Required Software
1. **Android NDK r26 or newer** - Download from [Android Developer](https://developer.android.com/ndk/downloads)
   - Extract to a local directory (e.g., `D:\Android\ndk\26.1.10909125`)
   - Note the path for the build scripts

2. **CMake 3.22+** - Included with Android NDK
   - Located at: `{NDK_PATH}\cmake\3.22.1\bin\cmake.exe`

3. **Ninja** - Included with Android NDK
   - Located at: `{NDK_PATH}\prebuilt\windows-x86_64\ninja.exe`

4. **OpenBLAS Libraries** - Required for optimized math operations
   - Download or build for both ARM architectures
   - Place in `android/src/main/jniLibs/{abi}/libopenblas.so`

### Directory Structure
```
maathai_llamma/
├── android/
│   └── src/main/
│       ├── cpp/                    # Native C++ source
│       └── jniLibs/               # Prebuilt libraries
│           ├── arm64-v8a/
│           │   └── libopenblas.so  # Required
│           └── armeabi-v7a/
│               └── libopenblas.so  # Required
├── build_offline.bat              # Windows batch script
├── build_offline.ps1              # PowerShell script
└── download_openblas.ps1          # OpenBLAS setup helper
```

## Quick Start

### 1. Set Up OpenBLAS Libraries

**Option A: Use the helper script**
```powershell
cd maathai_llamma
.\download_openblas.ps1
```

**Option B: Manual setup**
1. Download OpenBLAS source: `git clone https://github.com/xianyi/OpenBLAS.git`
2. Build for Android (see `setup_openblas_manual.sh`)
3. Copy `libopenblas.so` to both `jniLibs` directories

### 2. Update Build Script Paths

Edit `build_offline.bat` or `build_offline.ps1` and update:
```batch
set ANDROID_NDK_PATH=D:\Android\ndk\26.1.10909125
```

### 3. Run the Build

**Windows Batch:**
```cmd
cd maathai_llamma
build_offline.bat
```

**PowerShell:**
```powershell
cd maathai_llamma
.\build_offline.ps1 -AndroidNdkPath "D:\Android\ndk\26.1.10909125"
```

## Build Process Details

### What the Script Does

1. **Validates Prerequisites**
   - Checks NDK, CMake, and Ninja paths
   - Verifies OpenBLAS libraries exist

2. **Builds for Both Architectures**
   - `arm64-v8a` (64-bit ARM)
   - `armeabi-v7a` (32-bit ARM)

3. **CMake Configuration**
   - Enables OpenBLAS acceleration (`GGML_BLAS=ON`)
   - Enables OpenMP threading (`GGML_OPENMP=ON`)
   - Optimizes for mobile (`CMAKE_BUILD_TYPE=Release`)
   - Targets Android API 21+

4. **Ninja Compilation**
   - Compiles llama.cpp with optimizations
   - Links with OpenBLAS and OpenMP
   - Produces `libmaathai_llamma.so`

5. **Library Deployment**
   - Copies built libraries to `jniLibs` directories
   - Ready for Flutter plugin integration

### Build Output

After successful build, you'll have:
```
android/src/main/jniLibs/
├── arm64-v8a/
│   ├── libopenblas.so      # Prebuilt OpenBLAS
│   └── libmaathai_llamma.so # Built native library
└── armeabi-v7a/
    ├── libopenblas.so      # Prebuilt OpenBLAS
    └── libmaathai_llamma.so # Built native library
```

## Testing the Build

### 1. Build Flutter Plugin
```bash
cd maathai_llamma
flutter build aar
```

### 2. Run Example App
```bash
cd example
flutter run -d <device_id>
```

### 3. Verify Performance
```bash
adb logcat | findstr "MaathaiLL-NATIVE"
```

Look for:
- OpenBLAS library loading confirmation
- Performance timing logs
- No error messages

## Performance Optimizations

The build includes several optimizations for mobile inference:

### Math Acceleration
- **OpenBLAS**: Optimized linear algebra operations
- **OpenMP**: Multi-threading support
- **ARM NEON**: SIMD instructions for ARM processors

### Compilation Flags
- `-O3`: Maximum optimization
- `-DNDEBUG`: Remove debug code
- `-march=armv8-a`: ARM64 optimizations
- `-mfpu=neon`: NEON SIMD support

### Memory Management
- Shared libraries for smaller footprint
- Position-independent code (PIC)
- Optimized for mobile memory constraints

## Troubleshooting

### Common Issues

**1. OpenBLAS Library Missing**
```
ERROR: libopenblas.so not found for ABI arm64-v8a
```
**Solution**: Download and place OpenBLAS libraries in `jniLibs` directories

**2. NDK Path Incorrect**
```
ERROR: Android NDK not found at D:\Android\ndk\...
```
**Solution**: Update `ANDROID_NDK_PATH` in build scripts

**3. CMake Configuration Failed**
```
ERROR: CMake configuration failed
```
**Solution**: Check NDK version (r26+), verify toolchain file exists

**4. Build Fails with Linker Errors**
```
ERROR: Build failed for arm64-v8a
```
**Solution**: Ensure OpenBLAS library matches target architecture

### Debug Mode

To build with debug symbols:
```powershell
.\build_offline.ps1 -BuildType "Debug"
```

### Clean Build

To start fresh:
```cmd
rmdir /s build
build_offline.bat
```

## Advanced Configuration

### Custom CMake Options

Edit `android/src/main/cpp/CMakeLists.txt` to modify:
- BLAS vendor (OpenBLAS, MKL, etc.)
- OpenMP settings
- Compilation flags
- Target Android API level

### Architecture-Specific Builds

To build only one architecture, modify the build script:
```batch
set ABIS=arm64-v8a
```

### Performance Tuning

For maximum performance, consider:
- Using 4-bit quantized models
- Optimizing thread count for target device
- Enabling Vulkan backend (experimental)
- Using device-specific compiler flags

## Next Steps

After successful build:

1. **Integrate with Flutter App**
   - Add plugin to `pubspec.yaml`
   - Import and use in Dart code

2. **Deploy to Device**
   - Test on physical Android device
   - Monitor performance with profiling tools

3. **Optimize Further**
   - Profile with Android Studio
   - Tune model parameters
   - Test different model sizes

## Support

For issues or questions:
- Check the troubleshooting section above
- Review CMake and NDK documentation
- Test with minimal example first
- Verify all prerequisites are correctly installed
