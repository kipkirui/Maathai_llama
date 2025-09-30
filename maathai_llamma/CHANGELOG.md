## 0.0.1

### Changed
- Default `maxTokens` for synchronous and streaming generation now 512 (was 128).
- Passing `maxTokens <= 0` generates until EOS with a 1024-token safety cap tied to remaining context.
- Example app and tests updated to reflect new defaults.
- Documentation updated to explain the new behavior.
