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
copy build-arm64\lib\libopenblas.so .\android\src\main\jniLibs\arm64-v8a\
copy build-armv7\lib\libopenblas.so .\android\src\main\jniLibs\armeabi-v7a\

# 6. Verify
dir .\android\src\main\jniLibs\arm64-v8a\libopenblas.so
dir .\android\src\main\jniLibs\armeabi-v7a\libopenblas.so
