# Contributing to Maathai Llamma

Thanks for your interest in contributing! We welcome issues, bug fixes, new features, documentation improvements, and discussions.

## Code of Conduct

By participating, you agree to follow our [Code of Conduct](CODE_OF_CONDUCT.md).

## Getting Started

- Prerequisites: Flutter 3.3+, Dart SDK 3.9+, Android NDK r26+, CMake 3.22+
- Submodules: `git submodule update --init --recursive`
- Build/run example:
  ```bash
  cd maathai_llamma
  flutter pub get
  cd example
  flutter run
  ```
- Offline/optimized builds: see `maathai_llamma/BUILD_INSTRUCTIONS.md`.

## Development Workflow

1. Fork and create a feature branch: `git checkout -b feat/my-change`
2. Run linters and tests locally:
   ```bash
   dart format .
   dart analyze .
   flutter test
   ```
3. Commit with clear messages and open a PR.
4. Ensure CI is green and address review feedback.

## Pull Request Guidelines

- Include a clear description, motivation, and screenshots/logs where helpful.
- Update docs and example code if behavior changes.
- Add tests when fixing bugs or adding features.
- Keep PRs focused and under ~500 lines where possible.

## Issue Reporting

- Use the issue templates.
- Provide environment, steps to reproduce, expected/actual behavior, and logs.

## Licensing

By contributing, you agree your contributions will be licensed under the project’s [MIT License](LICENSE). The project vendors `llama.cpp` under its own licenses located in `maathai_llamma/extern/llama.cpp/licenses`.
