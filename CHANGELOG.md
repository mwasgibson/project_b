# Changelog

## Unreleased
### Added
- Phase 3 (start): GeolocatorLocationTracker writes `raw_points`; pause/resume; battery modes.
- RawPointsRepository; Timeline point count and last sample time.
- Tracking settings (S14 partial) and Samsung keep-alive guide (S22).
- Phase 2 onboarding: welcome disclosure (S1), foreground location (S2), background disclosure (S3).
- PermissionService; Android/iOS permission strings; Timeline permission cards.
- Display name Project B.

### Fixed
- Permission loop: after S3, show Open settings instead of re-prompting Start tracking.

### Earlier
- Project skeleton: feature-first structure, Riverpod, go_router with four tabs.
- Theme from the design brief (light, dark, system) with contrast tests.
- Local Drift schema for all tables in docs/05 Part A.
- Settings store and Appearance screen.
- Bootstrap script, CI workflow, lint rules.
