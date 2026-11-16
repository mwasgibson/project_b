import 'dart:async';
import 'dart:io';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/db/raw_points_repository.dart';
import '../../../core/permissions/permission_service.dart';
import '../../../domain/tracking/location_tracker.dart';

/// Free geolocator-based tracker for personal Android use.
///
/// On Android, starts a location-type foreground service with a persistent
/// notification so updates continue after Home. Surviving a full swipe-kill
/// still needs a separate headless engine (later) or Transistorsoft.
class GeolocatorLocationTracker implements LocationTracker {
  GeolocatorLocationTracker({
    required RawPointsRepository points,
    required PermissionService permissions,
  })  : _points = points,
        _permissions = permissions;

  final RawPointsRepository _points;
  final PermissionService _permissions;
  final Battery _battery = Battery();

  final _statusController = StreamController<TrackingStatus>.broadcast();
  StreamSubscription<Position>? _positionSub;

  TrackingStatus _status = TrackingStatus.off;
  TrackingMode _mode = TrackingMode.balanced;
  int? _lastPointAt;
  bool _wantTracking = false;

  @override
  Stream<TrackingStatus> get status async* {
    yield _status;
    yield* _statusController.stream;
  }

  @override
  TrackingStatus get currentStatus => _status;

  @override
  TrackingMode get currentMode => _mode;

  @override
  int? get lastPointAt => _lastPointAt;

  void _emit(TrackingStatus next) {
    if (_status == next) return;
    _status = next;
    _statusController.add(next);
  }

  LocationSettings _settingsFor(TrackingMode mode) {
    final accuracy = switch (mode) {
      TrackingMode.high => LocationAccuracy.best,
      TrackingMode.balanced => LocationAccuracy.high,
      TrackingMode.saver => LocationAccuracy.medium,
    };
    final distanceFilter = switch (mode) {
      TrackingMode.high => 10,
      TrackingMode.balanced => 25,
      TrackingMode.saver => 75,
    };

    // Android: foreground service + notification keeps sampling after Home.
    if (!kIsWeb && Platform.isAndroid) {
      return AndroidSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
        intervalDuration: switch (mode) {
          TrackingMode.high => const Duration(seconds: 5),
          TrackingMode.balanced => const Duration(seconds: 15),
          TrackingMode.saver => const Duration(seconds: 45),
        },
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Project B is tracking',
          notificationText:
              'Recording where you go. Data stays on this phone.',
          notificationChannelName: 'Location tracking',
          setOngoing: true,
          enableWakeLock: true,
        ),
      );
    }

    return LocationSettings(
      accuracy: accuracy,
      distanceFilter: distanceFilter,
    );
  }

  Future<TrackingStatus> _permissionStatus() async {
    final snap = await _permissions.snapshot();
    if (!snap.serviceEnabled) return TrackingStatus.locationServicesOff;
    if (!snap.hasForeground) return TrackingStatus.needsPermission;
    return TrackingStatus.off;
  }

  @override
  Future<void> start(TrackingMode mode) async {
    _mode = mode;
    _wantTracking = true;

    final blocked = await _permissionStatus();
    if (blocked != TrackingStatus.off) {
      _emit(blocked);
      return;
    }

    await _listen();
    _emit(TrackingStatus.on);
  }

  Future<void> _listen() async {
    await _positionSub?.cancel();
    _positionSub = Geolocator.getPositionStream(
      locationSettings: _settingsFor(_mode),
    ).listen(
      _onPosition,
      onError: (_) async {
        final blocked = await _permissionStatus();
        _emit(
          blocked == TrackingStatus.off
              ? TrackingStatus.needsPermission
              : blocked,
        );
      },
    );
  }

  Future<void> _onPosition(Position pos) async {
    if (!_wantTracking || _status == TrackingStatus.paused) return;

    int? batteryPct;
    try {
      batteryPct = await _battery.batteryLevel;
    } catch (_) {
      batteryPct = null;
    }

    final now = DateTime.now().toUtc();
    final offset = DateTime.now().timeZoneOffset.inMinutes;

    final sample = LocationSample(
      recordedAt: now.millisecondsSinceEpoch,
      utcOffsetMin: offset,
      lat: pos.latitude,
      lng: pos.longitude,
      accuracyM: pos.accuracy,
      speedMps: pos.speed >= 0 ? pos.speed : null,
      altitudeM: pos.altitude.isFinite ? pos.altitude : null,
      batteryPct: batteryPct,
      mode: _mode,
    );

    try {
      await _points.insertSample(sample);
      _lastPointAt = sample.recordedAt;
      if (_status != TrackingStatus.on) _emit(TrackingStatus.on);
    } catch (_) {
      // Keep listening; a single write failure must not stop the stream.
    }
  }

  @override
  Future<void> pause() async {
    if (!_wantTracking) return;
    await _positionSub?.cancel();
    _positionSub = null;
    _emit(TrackingStatus.paused);
  }

  @override
  Future<void> resume() async {
    if (!_wantTracking) {
      await start(_mode);
      return;
    }
    final blocked = await _permissionStatus();
    if (blocked != TrackingStatus.off) {
      _emit(blocked);
      return;
    }
    await _listen();
    _emit(TrackingStatus.on);
  }

  @override
  Future<void> stop() async {
    _wantTracking = false;
    await _positionSub?.cancel();
    _positionSub = null;
    _emit(TrackingStatus.off);
  }

  @override
  Future<void> setMode(TrackingMode mode) async {
    _mode = mode;
    if (_status == TrackingStatus.on) {
      await _listen();
    }
  }

  Future<void> dispose() async {
    await _positionSub?.cancel();
    await _statusController.close();
  }
}
