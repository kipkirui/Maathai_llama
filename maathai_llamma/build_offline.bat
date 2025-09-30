@echo off
REM Maathai Llamma Offline Build Script for Android
REM This script builds the native library completely offline using CMake and Ninja

setlocal enabledelayedexpansion

REM Configuration - Update these paths according to your setup
set ANDROID_NDK_PATH=D:\Android\ndk\26.1.10909125
set CMAKE_PATH=%ANDROID_NDK_PATH%\cmake\3.22.1\bin\cmake.exe
set NINJA_PATH=%ANDROID_NDK_PATH%\prebuilt\windows-x86_64\ninja.exe
set PROJECT_ROOT=%~dp0
set PLUGIN_ROOT=%PROJECT_ROOT%maathai_llamma
set EXTERN_ROOT=%PROJECT_ROOT%maathai_llamma\extern\llama.cpp

REM Check if NDK exists
if not exist "%ANDROID_NDK_PATH%" (
    echo ERROR: Android NDK not found at %ANDROID_NDK_PATH%
    echo Please update ANDROID_NDK_PATH in this script to point to your NDK installation
    pause
    exit /b 1
)

REM Check if CMake and Ninja exist
if not exist "%CMAKE_PATH%" (
    echo ERROR: CMake not found at %CMAKE_PATH%
    echo Please update CMAKE_PATH in this script
    pause
    exit /b 1
)

if not exist "%NINJA_PATH%" (
    echo ERROR: Ninja not found at %NINJA_PATH%
    echo Please update NINJA_PATH in this script
    pause
    exit /b 1
)

echo ========================================
echo Maathai Llamma Offline Build Script
echo ========================================
echo NDK Path: %ANDROID_NDK_PATH%
echo CMake Path: %CMAKE_PATH%
echo Ninja Path: %NINJA_PATH%
echo ========================================

REM Build for both architectures
set ABIS=arm64-v8a armeabi-v7a

for %%A in (%ABIS%) do (
    echo.
    echo Building for %%A...
    echo ========================================
    
    set BUILD_DIR=%PLUGIN_ROOT%\build\%%A
    set JNI_LIBS_DIR=%PLUGIN_ROOT%\android\src\main\jniLibs\%%A
    
    REM Create build directory
    if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"
    
    REM Check if OpenBLAS library exists
    set OPENBLAS_LIB=%JNI_LIBS_DIR%\libopenblas.so
    if not exist "!OPENBLAS_LIB!" (
        echo ERROR: OpenBLAS library not found at !OPENBLAS_LIB!
        echo Please download and place libopenblas.so for %%A architecture
        echo Download from: https://github.com/xianyi/OpenBLAS/releases
        echo Or build from source for Android
        pause
        exit /b 1
    )
    
    REM Configure with CMake
    echo Configuring CMake for %%A...
    "%CMAKE_PATH%" ^
        -S "%PLUGIN_ROOT%\android\src\main\cpp" ^
        -B "%BUILD_DIR%" ^
        -DCMAKE_TOOLCHAIN_FILE="%ANDROID_NDK_PATH%\build\cmake\android.toolchain.cmake" ^
        -DANDROID_ABI=%%A ^
        -DANDROID_PLATFORM=android-21 ^
        -DCMAKE_BUILD_TYPE=Release ^
        -DCMAKE_MAKE_PROGRAM="%NINJA_PATH%" ^
        -G Ninja
    
    if errorlevel 1 (
        echo ERROR: CMake configuration failed for %%A
        pause
        exit /b 1
    )
    
    REM Build with Ninja
    echo Building with Ninja for %%A...
    "%CMAKE_PATH%" --build "%BUILD_DIR%" --target maathai_llamma
    
    if errorlevel 1 (
        echo ERROR: Build failed for %%A
        pause
        exit /b 1
    )
    
    REM Copy the built library to jniLibs
    set OUTPUT_LIB=%BUILD_DIR%\maathai_llamma\libmaathai_llamma.so
    if exist "!OUTPUT_LIB!" (
        echo Copying libmaathai_llamma.so to jniLibs...
        copy "!OUTPUT_LIB!" "!JNI_LIBS_DIR!\" >nul
        echo ✓ Successfully built and copied libmaathai_llamma.so for %%A
    ) else (
        echo ERROR: Output library not found at !OUTPUT_LIB!
        pause
        exit /b 1
    )
)

echo.
echo ========================================
echo Build completed successfully!
echo ========================================
echo Native libraries have been built and copied to:
echo   - %PLUGIN_ROOT%\android\src\main\jniLibs\arm64-v8a\libmaathai_llamma.so
echo   - %PLUGIN_ROOT%\android\src\main\jniLibs\armeabi-v7a\libmaathai_llamma.so
echo.
echo You can now:
echo 1. Build the Flutter plugin: flutter build aar
echo 2. Run the example app: flutter run -d <device>
echo 3. Check logs with: adb logcat | findstr "MaathaiLL-NATIVE"
echo ========================================
pause
