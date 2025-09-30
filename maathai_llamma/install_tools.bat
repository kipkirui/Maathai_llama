@echo off
REM Maathai Llamma - Tool Installation Script
REM This script helps install CMake and Ninja for building the project

echo ========================================
echo Maathai Llamma - Tool Installation
echo ========================================
echo.

echo Checking current tools...
echo.

REM Check if CMake is available
cmake --version >nul 2>&1
if %errorlevel% equ 0 (
    echo ✓ CMake is already installed
    cmake --version
) else (
    echo ✗ CMake not found
)

echo.

REM Check if Ninja is available
ninja --version >nul 2>&1
if %errorlevel% equ 0 (
    echo ✓ Ninja is already installed
    ninja --version
) else (
    echo ✗ Ninja not found
)

echo.
echo ========================================
echo Installation Options
echo ========================================
echo.

echo Option 1: Install via Chocolatey (Recommended)
echo ------------------------------------------------
echo 1. Install Chocolatey:
echo    Set-ExecutionPolicy Bypass -Scope Process -Force
echo    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
echo    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
echo.
echo 2. Install tools:
echo    choco install cmake ninja -y
echo.
echo 3. Refresh environment:
echo    refreshenv
echo.

echo Option 2: Manual Installation
echo ------------------------------
echo 1. Download CMake from: https://cmake.org/download/
echo 2. Download Ninja from: https://github.com/ninja-build/ninja/releases
echo 3. Add both to your system PATH
echo.

echo Option 3: Use Android Studio's CMake
echo -------------------------------------
echo Check if CMake is available at:
echo C:\Users\%USERNAME%\AppData\Local\Android\Sdk\cmake\
echo.

echo ========================================
echo Next Steps
echo ========================================
echo.
echo After installing the tools:
echo 1. Run: .\build_offline_no_openblas.ps1 -AndroidNdkPath "C:\Users\%USERNAME%\AppData\Local\Android\Sdk\ndk\27.0.12077973"
echo 2. Or run: .\build_offline.ps1 (if you have OpenBLAS libraries)
echo.

pause
