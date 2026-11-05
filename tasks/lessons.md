# Lessons

- Do not pin package versions from memory; let `flutter pub add` resolve current versions. Code is written against APIs stable across recent major versions (e.g. Riverpod `Provider`/`StreamProvider`, not `StateProvider`).
- Generated files (`*.g.dart`) are not committed; CI and bootstrap run build_runner.
- Do not claim code works unless it has been run. State what was and was not verified.
- The sandbox shell has no brace expansion: create folders with explicit paths.
