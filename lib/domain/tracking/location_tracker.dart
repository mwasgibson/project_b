/// How often and how precisely the phone samples location.
/// Mirrors the three modes in docs/01 (F3).
enum TrackingMode { high, balanced, saver }

enum TrackingStatus {
  /// Recording.
  on,

  /// User paused tracking.
  paused,

  /// Tracking is wanted but a permission is missing or was revoked.
  needsPermission,

  /// Phone-level location services are switched off.
  locationServicesOff,

  /// Not recording.
  off,
}

/// Boundary around the platform tracking plugin (docs/02).
/// Phase 3 implements this; the rest of the app depends only on this interface,
/// so a paid plugin can be swapped for a free one without touching UI code.
abstract interface class LocationTracker {
  Stream<TrackingStatus> get status;

  Future<void> start(TrackingMode mode);

  Future<void> pause();

  Future<void> stop();

  Future<void> setMode(TrackingMode mode);
}
