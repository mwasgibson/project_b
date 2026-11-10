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
- [ ] **You:** walk outdoors with tracking on; confirm point count rises
- [ ] **You:** apply Samsung unrestricted battery (S22)
- [ ] Android foreground-service notification (keeps process alive when screen off)
- [ ] Boot restart / resume after kill
- [ ] Auto-saver at low battery
- [ ] Health check + gap recording
- [ ] Multi-day battery log in docs/06

## Next after outdoor smoke test
Foreground service notification, then multi-day soak on Samsung.
