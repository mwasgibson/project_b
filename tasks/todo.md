# Todo

## Plan: Phase 0 + Phase 1 (docs/06-implementation-plan.md)
Goal: app shell with navigation, theme, local database. Runs on the Samsung and iOS simulator.

### Phase 0: Setup
- [x] Repo skeleton, lint rules, CI workflow, .gitignore, env example
- [x] Bootstrap script (generates android/ios, adds packages, runs codegen, analyze, test)
- [ ] **You:** run `tool/bootstrap.sh` on the Mac; `flutter doctor` clean
- [ ] **You:** pick final app name + package/bundle id (script defaults to `com.example.projectb`)
- [ ] **You:** create dev Supabase project (not wired yet)
- [ ] **You:** run on the Samsung and in the iOS simulator

### Phase 1: Foundations
- [x] Feature-first folder structure, Riverpod, go_router with 4 tabs (docs/03)
- [x] Theme from docs/04 tokens, light/dark/system; contrast checked numerically
- [x] Drift schema from docs/05 Part A (all local tables), FK pragma on
- [x] Settings store + Appearance screen (S16)
- [x] Reusable widgets: TrackingStatusChip, EmptyState, ContentWidth
- [x] `LocationTracker` interface (implemented in Phase 3)
- [x] Tests: palette contrast, DB roundtrip + FK, widget tests
- [ ] **Verify on Mac:** `flutter analyze` clean, `flutter test` green, theme switch works on device

## Review
Written without a Flutter SDK available (the sandbox cannot reach the Flutter download host), so nothing here has been compiled or run. Palette contrast was verified numerically with a script. First real verification is `tool/bootstrap.sh`.
