# Maathai `llama.cpp` Flutter Plugin

This plugin packages [`llama.cpp`](https://github.com/ggml-org/llama.cpp) so Flutter apps can load GGUF models and chat fully offline. The initial release focuses on Android (NDK-based build), with room to extend to other targets.

## Directory Layout

- `lib/`: Dart API exposing initialize → loadModel → generate → release lifecycle.
- `android/`: Native bridge (`maathai_llamma_bridge.cpp`) builds `llama.cpp` and exposes JNI entry points.
- `extern/llama.cpp`: Git submodule tracking upstream inference runtime.
- `example/`: Flutter UI that lets you pick a local model path and exchange prompts.

## Prerequisites (Android)

1. **Android Studio / SDK** with NDK `26.1.10909125` and CMake `3.22.1`.
2. **Flutter 3.3+** with compatible Dart SDK.
3. GGUF model stored locally on the device/emulator.

## Build Steps

```powershell
git clone https://github.com/your-org/maathai_llamma.git
cd maathai_llamma
git submodule update --init --recursive
flutter pub get
```

To validate the plugin and example:

```powershell
cd example
flutter run --device-id <your-device>
```

The build will compile `llama.cpp` for each Android ABI via CMake and bundle the shared library `libmaathai_llamma.so`.

## Runtime Workflow

1. `MaathaiLlamma.initialize()` — calls `llama_backend_init` once per process.
2. `loadModel(modelPath, contextLength, threads, gpuLayers)` — loads a GGUF model, configures context size & thread count, and prepares a sampler chain (temperature + top-k/top-p).
3. `generate(prompt, maxTokens)` — sends the prompt to the native side, runs a decoding loop, and returns sampled tokens as a string.
4. `release()` — frees model, context, and sampler.

See `example/lib/main.dart` for an end-to-end chat UI.

## Android Integration Tips

- The plugin builds against `c++_shared`. If your host app already includes another STL, align them to avoid duplicate symbols.
- Ensure ABI folders (`android/src/main/jniLibs/<abi>`) contain `libc++_shared.so` or rely on Gradle packaging from the NDK.
- For large models, expect high memory pressure. Prefer quantized (Q4/Q5) variants for mid-range devices.

## Roadmap

- [ ] iOS/macOS support via upstream XCFramework.
- [ ] Streaming token events via `EventChannel`.
- [ ] Model metadata inspection in Dart.
- [ ] Integration tests with on-device smoke model.

Contributions welcome! Open an issue or PR to discuss enhancements.



