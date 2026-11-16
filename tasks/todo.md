# Todo

## Phase 0–2 — done
Verified on Samsung. Permission loop fixed.

## Phase 3: Tracking engine (in progress)
Goal: reliable background tracking on the Samsung.

- [x] Expand LocationTracker + LocationSample
- [x] RawPointsRepository
- [x] GeolocatorLocationTracker (free path; interface allows Transistorsoft later)
- [x] Timeline: status, pause/resume, point count, start
- [x] Tracking settings (modes) + S22 keep-alive guide
- [x] Outdoor / near-home smoke test on SM A176B (points recorded, 2026-11-16)
- [x] Android FGS notification via geolocator ForegroundNotificationConfig
- [ ] **You:** Start tracking, press Home, walk; confirm notification stays and point count rises
- [ ] **You:** apply Samsung unrestricted battery (S22) if not already
- [ ] Survive swipe-from-recents (headless / flutter_foreground_task) — optional hardening
- [ ] Boot restart / resume after kill
- [ ] Auto-saver at low battery
- [ ] Health check + gap recording
- [ ] Multi-day battery log in docs/06

## Next
Verify FGS notification on Samsung with screen off / Home, then multi-day soak.
