# Workspace Notes

This workspace houses the Maathai `llama.cpp` Flutter plugin (`maathai_llamma/`). Use this document for high-level setup guidance.

## Initial Tasks

- Review `maathai_llamma/README.md` for plugin documentation.
- Android build chain: install NDK 26.1.10909125 and CMake 3.22.1.
- Fetch submodule: `git submodule update --init --recursive`.

## Build Commands

```powershell
cd maathai_llamma
flutter pub get
cd example
flutter run --device-id <device>
```

## Additional Resources

- llama.cpp upstream docs: https://github.com/ggml-org/llama.cpp
- Flutter plugin authoring: https://flutter.dev/to/develop-plugins

