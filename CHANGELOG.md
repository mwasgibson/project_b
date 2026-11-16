# Changelog

## Unreleased
### Added
- Phase 3: GeolocatorLocationTracker writes `raw_points`; pause/resume; battery modes.
- Android foreground notification so sampling continues after Home.
- TrackingSession: gaps on pause/permission/stop, auto-saver at low battery, resume on app start.
- Health label in Tracking settings; 30‑minute stale banner on Timeline.
- RawPointsRepository; Timeline point count and last sample time.
- Tracking settings (S14) and Samsung keep-alive guide (S22).
- Phase 2 onboarding S1–S3; PermissionService; platform permission strings.
- Display name Project B.

### Fixed
- Permission loop after S3.

### Earlier
- Foundations: theme, router, Drift schema, settings, shell, tests.
