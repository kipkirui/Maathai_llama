# Manual OpenBLAS Setup Instructions
# =================================

# 1. Download OpenBLAS source
git clone https://github.com/xianyi/OpenBLAS.git
cd OpenBLAS

# 2. Build for Android ARM64
mkdir build-arm64
cd build-arm64
cmake .. \
  -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK/build/cmake/android.toolchain.cmake \
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
  -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK/build/cmake/android.toolchain.cmake \
  -DANDROID_ABI=armeabi-v7a \
  -DANDROID_PLATFORM=android-21 \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=ON
make -j4

# 4. Copy libraries
cp build-arm64/libopenblas.so .\maathai_llamma\android\src\main\jniLibs\arm64-v8a/
cp build-armv7/libopenblas.so .\maathai_llamma\android\src\main\jniLibs\armeabi-v7a/

# 5. Verify files exist
ls -la .\maathai_llamma\android\src\main\jniLibs\arm64-v8a/libopenblas.so
ls -la .\maathai_llamma\android\src\main\jniLibs\armeabi-v7a/libopenblas.so
