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
- [x] Outdoor / near-home smoke test on SM A176B (2026-11-16)
- [x] Android FGS notification via geolocator ForegroundNotificationConfig
- [x] GapsRepository + gap open/close on pause / permission / stop
- [x] Auto-saver at low battery (default 20%, configurable)
- [x] Health label + 30 min stale warning on Timeline
- [x] Resume tracking on app start when tracking_enabled
- [ ] **You:** Start tracking, Home, walk; FGS notification + rising point count
- [ ] **You:** Unrestricted battery on Samsung (S22)
- [ ] Survive swipe-from-recents (headless engine) — optional hardening
- [ ] Boot restart (RECEIVE_BOOT_COMPLETED wiring)
- [ ] Multi-day battery log in docs/06

## Next
Verify FGS + auto-saver on device, then Phase 4 segmentation when you have a day of points.
