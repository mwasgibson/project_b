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

/// One GPS sample as written to `raw_points`.
class LocationSample {
  const LocationSample({
    required this.recordedAt,
    required this.utcOffsetMin,
    required this.lat,
    required this.lng,
    this.accuracyM,
    this.speedMps,
    this.altitudeM,
    this.activity,
    this.batteryPct,
    required this.mode,
  });

  final int recordedAt;
  final int utcOffsetMin;
  final double lat;
  final double lng;
  final double? accuracyM;
  final double? speedMps;
  final double? altitudeM;
  final String? activity;
  final int? batteryPct;
  final TrackingMode mode;
}

/// Boundary around the platform tracking plugin (docs/02).
/// Phase 3 implements this; the rest of the app depends only on this interface,
/// so a paid plugin can be swapped for a free one without touching UI code.
abstract interface class LocationTracker {
  Stream<TrackingStatus> get status;

  TrackingStatus get currentStatus;

  TrackingMode get currentMode;

  /// UTC ms of the last successfully written point, or null.
  int? get lastPointAt;

  Future<void> start(TrackingMode mode);

  Future<void> pause();

  Future<void> resume();

  Future<void> stop();

  Future<void> setMode(TrackingMode mode);
}
