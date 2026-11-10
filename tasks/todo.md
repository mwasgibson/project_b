# Todo

## Phase 0 + 1 — done
Verified on Samsung and iOS simulator. Display name: Project B.

## Phase 2: Onboarding and permissions (F1)
Goal: honest, correct permission flow.

- [x] S1 Welcome / disclosure
- [x] S2 Foreground location request
- [x] S3 Background disclosure + Always request (on Start tracking)
- [x] PermissionService + providers
- [x] Android manifest location / notification / FGS permissions
- [x] iOS Info.plist usage strings + background location mode
- [x] Router redirect when onboarding incomplete
- [x] Timeline cards for denied / services off / start tracking
- [ ] **You:** `fvm flutter pub get` then run on Samsung; walk grant + deny paths
- [ ] **You:** confirm Android shows background permission only after S3 Continue
- [ ] S4 notification permission (deferred until first reminder in Phase 6)
- [ ] Draft privacy-policy text (reuse disclosure copy; full page at Phase 10)

## Decisions locked
- Name: Project B (no underscore in display)
- Supabase: Phase 9 only
- No physical iPhone soon → Android-first for tracking (Phase 3); iOS sim for UI

## Next
Phase 3 tracking engine once Phase 2 is verified on the Samsung.
