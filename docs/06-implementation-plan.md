# Implementation Plan: Project B

## Approach
Build order follows risk. The riskiest thing in this app is **reliable background tracking on real phones** (Samsung especially, then iOS), so it gets proven early, before polish or sync. Everything else (UI, calendar, weather, sync) is well-understood and comes after.

Rules for the build:
1. Keep every external dependency behind an interface: `LocationTracker`, `PlaceResolver`, `WeatherProvider`, `SyncBackend`.
2. Local-first: every feature must work with no account and no internet before it touches the cloud.
3. Each phase ends with something you can run on your phone.
4. No deadline, so finish a phase properly before starting the next.

Tracking feature IDs refer to doc 01 (F1 to F9). Screen IDs refer to doc 03.

**Lived path, constraints, and divergences from this plan:** see [docs/07-build-roadmap.md](07-build-roadmap.md).

## Phases

### Phase 0: Setup and decisions
Goal: a clean repo and a working "hello world" on your Samsung.
Tasks:
- [x] Install Flutter, Android Studio, Xcode (on the Mac); run `flutter doctor` clean.
- [x] Create repo, add `docs/` from this kickoff, set up lint rules and CI (analyze + test).
- [x] App name: Project B (display); package remains without underscore.
- [ ] Create the dev Supabase project (do not wire it up yet) — deferred to Phase 9.
- [x] No physical iPhone planned; Android-first for tracking, iOS simulator for UI only.
Done when: the blank app runs on the Samsung and in the iOS simulator, and CI is green.

### Phase 1: Foundations
Goal: app shell with navigation, theme and local database.
Tasks:
- [x] App structure (feature folders), Riverpod, router with the four tabs (doc 03).
- [x] Theme: light/dark/system from doc 04 tokens; check contrast.
- [x] Drift database with the local tables from doc 05 and migration tests.
- [x] Settings store and S16 Appearance (F8 part).
- [x] Reusable components: status chip, rows, empty states, skeletons.
Done when: you can switch themes, navigate all tabs with placeholder content, and DB migrations pass tests.

### Phase 2: Onboarding and permissions (F1)
Goal: honest, correct permission flow.
Tasks:
- [x] Screens S1–S3 and S3's prominent disclosure (S4 deferred to Phase 6 with first reminder).
- [x] Android manifest and iOS Info.plist entries (doc 02).
- [x] Foreground-first, background-on-enable logic; denied/revoked states on Timeline.
- [ ] Draft the privacy policy text and in-app disclosure copy (needed again in Phase 10).
Done when: every permission path (granted, denied, later revoked) behaves as in doc 03 on Android (primary); iOS simulator for UI checks.

### Phase 3: Tracking engine (F2, F3), the riskiest phase
Goal: reliable background tracking you can trust.
Tasks:
- [x] Define `LocationTracker` interface.
- [x] Implement with free Geolocator path and write `raw_points` (Transistorsoft optional later via same interface).
- [x] Android foreground-service notification with pause/resume; resume on app start.
- [ ] Boot restart (RECEIVE_BOOT_COMPLETED wiring).
- [x] Three battery modes and the auto-saver-at-low-battery rule.
- [x] Tracking health check and gap recording.
- [x] Keep-alive guide S22 for Samsung battery optimisation.
- [ ] Head-to-head test of a free native-service plugin against a paid one; record results (optional for personal use).
- [ ] Battery log: note battery % at fixed times per mode over several days.
- [ ] Survive swipe-from-recents (headless) — optional hardening.
- [ ] iOS: Always permission, significant-change/visit handling — deferred until a real iPhone is available; keep interface clean so iOS can land later.
Done when: 3 consecutive days of normal life on the Samsung with screen off give a plausible point trail with no unexplained gaps over 30 minutes, and balanced mode battery cost is within the target in doc 01.
**Status:** Core engine usable on Samsung (smoke-tested 2026-11-16). Multi-day soak and boot/swipe-kill still open.

### Phase 4: Segmentation and timeline (F4)
Goal: raw points become a readable day.
Tasks:
- [x] Segmenter with unit tests on synthetic data (stay, short stop, two visits + trip).
- [x] Visit/trip/gap tables populated incrementally.
- [x] Timeline today (S5) with visit/trip list and visit detail (S7); day map S6 deferred.
- [x] Edit actions: rename (via Phase 5 place), delete; `user_edited` protection.
- [ ] Tune thresholds (100 m / 10 min defaults) against your own real multi-day data.
- [ ] Trip detail S8 / day map S6.
Done when: your real day from Phase 3 reads correctly, and edits survive re-segmentation.
**Status:** Core list timeline + segmenter done; map views and long-data threshold tuning open.

### Phase 5: Place labelling (F5)
Goal: names instead of coordinates.
Tasks:
- [x] `PlaceResolver` with the platform geocoder implementation.
- [x] Labelling queue with retry when offline; `label_state` handling.
- [x] Place matching within radius; user rename reused for nearby visits.
- [x] Auto-label switch and disclosure about the geocoder; rename from visit detail.
- [ ] Places screen S15.
- [ ] Optional offline city fallback.
Done when: new visits get names online, stay pending offline, and user renames are reused.
**Status:** Core labelling + rename done; S15 and offline pack optional.

### Phase 6: Calendar and reminders (F6)
Goal: a calendar that also shows your movements.
Tasks:
- [ ] Month (S9) and day (S10) views merging events and timeline entries.
- [ ] Event editor S11 with validation.
- [ ] Local notifications, rescheduling after reboot, cancelling on delete.
- [ ] `.ics` export.
Done when: a reminder fires reliably after a reboot and after the app is force-closed, on both platforms.

### Phase 7: Weather (F7)
Goal: forecast on the calendar.
Tasks:
- [ ] `WeatherProvider` (Open-Meteo), coordinate rounding, cache table.
- [ ] Weather screen S12; weather chip on S10 and event editor.
- [ ] Offline stale-data label.
Done when: weather shows online, cached offline, and never sends full-precision coordinates.

### Phase 8: Data control and settings polish (F8)
Goal: user is in charge of their data.
Tasks:
- [ ] Retention job and setting.
- [ ] Export JSON and GPX; delete-all with typed confirmation.
- [ ] Units setting; tracking settings screen S14 complete.
- [ ] Full accessibility pass: screen reader labels, large text, reduce motion.
Done when: you can export, wipe and re-import (or at least inspect) your data, and the app passes the accessibility checks in doc 04.

### MVP checkpoint
Use the app daily for 1 to 2 weeks before building sync. Fix what annoys you. This is the real test of whether tracking, battery and the timeline are good enough.

### Phase 9: Encrypted cloud sync (F9)
Goal: optional sync nobody else can read.
Tasks:
- [ ] Create Supabase schema, RLS and RPCs from doc 05; test RLS with two accounts.
- [ ] Crypto module: Argon2id key derivation, key wrapping, recovery key, record encryption; unit tests including wrong-passphrase.
- [ ] Sync engine: outbox, push/pull with cursor, last-write-wins, tombstones.
- [ ] Screens S18 to S21; clear data-loss warning copy.
- [ ] Account deletion Edge Function and delete-cloud-data flow.
- [ ] Two-device test (Samsung + second phone or emulator): create, edit, delete on each, go offline, reconnect.
Done when: a fresh install restores the timeline from the cloud with the passphrase and with the recovery key, and the database contains only ciphertext.

### Phase 10: Hardening and release prep
Goal: ready for stores, even if only for your own use.
Tasks:
- [ ] Decide on the tracking plugin licence (or switch to the free alternative) before building release.
- [ ] Buy the Apple Developer Program membership; set up TestFlight.
- [ ] Google Play: Play Console account, background location declaration, demo video, in-app disclosure, foreground service type declaration, data safety form.
- [ ] Publish privacy policy at a public URL.
- [ ] Release signing, versioning, obfuscation, crash handling that does not collect location.
- [ ] Final battery and reliability soak test on both platforms.
Done when: a release build is installed from internal testing (Play) and TestFlight (Apple) on real devices and tracking runs for a week.

### Phase 11+: Later features (pick by value, one at a time)
- [ ] Location-based reminders (geofences)
- [ ] Gallery connection
- [ ] Weather-aware event suggestions
- [ ] Year / month in review
- [ ] Share
- [ ] Device calendar sync and other app integrations
- [ ] Google/Apple sign-in
Each gets its own mini-spec appended to doc 01 before building.

## Dependencies and sequencing
```mermaid
flowchart LR
  P0[0 Setup] --> P1[1 Foundations] --> P2[2 Permissions] --> P3[3 Tracking]
  P3 --> P4[4 Timeline] --> P5[5 Labelling]
  P1 --> P6[6 Calendar]
  P1 --> P7[7 Weather]
  P4 & P6 & P7 --> P8[8 Data control]
  P8 --> MVP{{MVP checkpoint}} --> P9[9 Sync] --> P10[10 Release prep]
```
- Phases 6 and 7 do not depend on tracking and can be done earlier if tracking tests need waiting days.
- Phase 3 testing needs elapsed real time (days), so start it early and build other phases while it collects data.
- Phase 10 depends on the plugin licence decision and the Apple membership.

## Testing and release checklist
- [ ] Unit and widget tests green in CI
- [ ] Manual: reboot, force-close, airplane mode, low battery, permission revoked mid-day
- [ ] Manual: Samsung battery optimisation on and off
- [ ] Manual: time zone and daylight changes (travel)
- [ ] RLS tested with two accounts; no service key in the app bundle
- [ ] Wrong-passphrase and lost-device restore verified
- [ ] Export and delete verified
- [ ] Accessibility checks from doc 04
- [ ] Play declaration and App Store privacy answers match what the app really does
- [ ] Privacy policy URL live

## Risks and mitigations
| Risk | Mitigation |
|---|---|
| OS kills background tracking | Foreground service, keep-alive guide, health check, early multi-day tests (Phase 3) |
| Plugin licence cost / lock-in | Interface + free alternative test before Phase 10 |
| Play Store rejection | Follow doc 02 and research doc section 4 from Phase 2 onwards, not at the end |
| No iPhone for iOS tracking tests | Android-first; keep LocationTracker interface; iOS when hardware appears |
| Battery complaints | Modes, auto-saver, battery log in Phase 3 |
| E2EE data loss | Recovery key, clear copy, tested restore path |
| Scope creep | Only features in doc 01 MVP before the checkpoint |
| Free-service terms change (weather, tiles, geocoder) | Provider interfaces, re-check terms in Phase 10 |

## Progress log
- 2026-10-22: Planning docs 00 to 06 created. No code written yet.
- 2026-10-24: Phase 0 skeleton and Phase 1 foundations written (theme, router, Drift schema, settings, shell, tests, bootstrap).
- 2026-11-05: Phase 1 verified on Samsung.
- 2026-11-10: iOS simulator build fixed (xcode-select / objective_c native assets); UI good. Decisions: display name Project B; no iPhone soon → Android-first; Supabase at Phase 9.
- 2026-11-10: Phase 2 onboarding + permissions (S1–S3, PermissionService, manifest/plist, Timeline permission cards).
- 2026-11-10: Phase 3 start — LocationTracker + Geolocator writer, Timeline controls, S14, S22.
- 2026-11-16: Permission loop fixed; FGS notification; outdoor smoke test on SM-A176B.
- 2026-11-16: TrackingSession (gaps, auto-saver, resume on start, health); theme/nav bug fixed (stable GoRouter).
- 2026-11-16: Phase 4 segmenter + timeline visits/trips + visit detail delete.
- 2026-11-16: Phase 5 PlaceResolver, label queue, auto-label toggle, user rename.
- 2026-11-17: docs/07-build-roadmap.md added (actual path, reasoning, constraints). Next: Phase 6 calendar.
