# Maathai Llamma - Complete Setup Guide

## Current Status
✅ Android NDK 27.0.12077973 found at: `C:\Users\user\AppData\Local\Android\Sdk\ndk\27.0.12077973`
❌ CMake not found in system PATH
❌ Ninja not found in system PATH
❌ OpenBLAS libraries not installed

## Prerequisites Installation

### Option 1: Install CMake and Ninja via Chocolatey (Recommended)

1. **Install Chocolatey** (if not already installed):
   ```powershell
   Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
   ```

2. **Install CMake and Ninja**:
   ```powershell
   choco install cmake ninja -y
   ```

3. **Refresh PATH**:
   ```powershell
   refreshenv
   ```

### Option 2: Manual Installation

1. **Download CMake**:
   - Go to https://cmake.org/download/
   - Download Windows x64 Installer
   - Install and add to PATH

2. **Download Ninja**:
   - Go to https://github.com/ninja-build/ninja/releases
   - Download ninja-win.zip
   - Extract to a folder (e.g., `C:\ninja`)
   - Add to PATH

### Option 3: Use Android Studio's CMake

If you have Android Studio installed, CMake might be available at:
```
C:\Users\user\AppData\Local\Android\Sdk\cmake\<version>\bin\cmake.exe
```

## OpenBLAS Setup

### Quick Setup (Recommended for Testing)

1. **Download prebuilt OpenBLAS libraries**:
   - Go to https://github.com/xianyi/OpenBLAS/releases
   - Download the latest release
   - Look for Android ARM builds or build from source

2. **Alternative: Use the no-OpenBLAS build**:
   - The project includes a CMakeLists.txt that works without OpenBLAS
   - Performance will be lower but functional for testing

### Manual OpenBLAS Build

1. **Clone OpenBLAS**:
   ```bash
   git clone https://github.com/xianyi/OpenBLAS.git
   cd OpenBLAS
   ```

2. **Build for Android ARM64**:
   ```bash
   mkdir build-arm64
   cd build-arm64
   cmake .. -DCMAKE_TOOLCHAIN_FILE=%ANDROID_NDK%/build/cmake/android.toolchain.cmake -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM=android-21 -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON -DNO_FORTRAN=1
   cmake --build . --config Release
   ```

3. **Build for Android ARMv7**:
   ```bash
   cd ..
   mkdir build-armv7
   cd build-armv7
   cmake .. -DCMAKE_TOOLCHAIN_FILE=%ANDROID_NDK%/build/cmake/android.toolchain.cmake -DANDROID_ABI=armeabi-v7a -DANDROID_PLATFORM=android-21 -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON -DNO_FORTRAN=1
   cmake --build . --config Release
   ```

4. **Copy libraries**:
   ```bash
   copy build-arm64\lib\libopenblas.so ..\..\maathai_llamma\android\src\main\jniLibs\arm64-v8a\
   copy build-armv7\lib\libopenblas.so ..\..\maathai_llamma\android\src\main\jniLibs\armeabi-v7a\
   ```

## Build Process

### Step 1: Verify Tools Installation

```powershell
cmake --version
ninja --version
```

### Step 2: Choose Build Method

#### Method A: With OpenBLAS (Recommended for Production)
```powershell
cd maathai_llamma
.\build_offline.ps1 -AndroidNdkPath "C:\Users\user\AppData\Local\Android\Sdk\ndk\27.0.12077973"
```

#### Method B: Without OpenBLAS (For Testing)
```powershell
cd maathai_llamma
.\build_offline_no_openblas.ps1 -AndroidNdkPath "C:\Users\user\AppData\Local\Android\Sdk\ndk\27.0.12077973"
```

### Step 3: Test the Build

```powershell
cd example
flutter run -d <device_id>
```

## Troubleshooting

### Common Issues

1. **CMake not found**:
   - Install CMake via Chocolatey or manually
   - Ensure it's in your PATH

2. **Ninja not found**:
   - Install Ninja via Chocolatey or manually
   - Ensure it's in your PATH

3. **OpenBLAS library missing**:
   - Use the no-OpenBLAS build for testing
   - Or build OpenBLAS from source

4. **NDK path incorrect**:
   - Update the AndroidNdkPath parameter
   - Use the correct NDK version path

### Verification Commands

```powershell
# Check NDK
dir "C:\Users\user\AppData\Local\Android\Sdk\ndk\27.0.12077973\"

# Check CMake
cmake --version

# Check Ninja
ninja --version

# Check OpenBLAS
dir ".\android\src\main\jniLibs\arm64-v8a\libopenblas.so"
dir ".\android\src\main\jniLibs\armeabi-v7a\libopenblas.so"
```

## Next Steps

1. **Install CMake and Ninja** using one of the methods above
2. **Set up OpenBLAS** (optional for initial testing)
3. **Run the build script** with the correct NDK path
4. **Test with Flutter example app**

## Performance Notes

- **With OpenBLAS**: 2-3x faster inference, optimized for mobile
- **Without OpenBLAS**: Basic functionality, suitable for testing
- **Recommended**: Use OpenBLAS for production builds

## Support

If you encounter issues:
1. Check the troubleshooting section above
2. Verify all prerequisites are installed
3. Use the no-OpenBLAS build for initial testing
4. Check the build logs for specific error messages
