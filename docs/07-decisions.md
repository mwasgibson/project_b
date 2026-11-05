# Architecture Decision Records

Format: context, decision, consequences. Add a new record for every significant choice; never edit history, supersede it.

## ADR-001: Flutter for both platforms
- **Date:** 2026-10-22
- **Context:** One developer, Android and iOS wanted, UI-focused app, developer background is Python.
- **Decision:** Flutter (Dart) with Riverpod and go_router.
- **Consequences:** One codebase. Background location relies on a native-backed plugin. Dart is new to learn. React Native stays a viable fallback (docs/00 section 3).

## ADR-002: Local-first, phone is the source of truth
- **Context:** Location history is sensitive. Google Timeline itself moved on-device with encrypted backup.
- **Decision:** All features work from SQLite (Drift). Cloud is optional backup and multi-device merge.
- **Consequences:** Offline works everywhere. We write our own small sync protocol instead of relying on a BaaS offline engine.

## ADR-003: Cloud stores ciphertext only
- **Context:** Row Level Security protects against other users, not a breach or a curious operator.
- **Decision:** Client-side encryption (Argon2id key derivation, random data key wrapped by passphrase and recovery key, authenticated per-record encryption). Raw GPS points are never synced.
- **Consequences:** A lost passphrase and recovery key means lost cloud data; the app must say so plainly. Server cannot search or analyse content.

## ADR-004: Supabase for sync backend
- **Context:** Needed Postgres, auth, free tier, exit path. Compared Firebase and self-hosted FastAPI (docs/00 section 5).
- **Decision:** Supabase, with RLS on every table.
- **Consequences:** Free projects pause after inactivity; pricing must be re-checked before launch. Self-hosting is the exit plan.

## ADR-005: Email one-time code sign-in only in v1
- **Context:** Offering Google sign-in can trigger Apple's Sign in with Apple requirement. Sign-in is needed only for sync.
- **Decision:** Email OTP only in v1; social sign-in later.
- **Consequences:** Less review friction. Slightly more typing for the user.

## ADR-006: Dependencies hidden behind interfaces
- **Decision:** `LocationTracker` now; `PlaceResolver`, `WeatherProvider`, `SyncBackend` when each is built (YAGNI: no empty interfaces before they have a user).
- **Consequences:** Paid or fragile plugins (e.g. the tracking plugin licence) can be replaced without UI changes.

## ADR-007: Packages added at bootstrap, not pinned from memory
- **Context:** Package versions drift; the first scaffold was written without SDK access.
- **Decision:** `flutter pub add` resolves current versions; code targets APIs stable across recent majors.
- **Consequences:** `pubspec.lock` is not committed for now; revisit once the app stabilises.
