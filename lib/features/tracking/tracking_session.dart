import 'dart:async';

import 'package:battery_plus/battery_plus.dart';

import '../../core/db/gaps_repository.dart';
import '../../core/db/raw_points_repository.dart';
import '../../core/settings/setting_keys.dart';
import '../../core/settings/settings_repository.dart';
import '../../domain/tracking/location_tracker.dart';

/// Coordinates the engine with settings, gaps, and low-battery auto-saver.
///
/// UI and bootstrap call this instead of the raw [LocationTracker] so pause,
/// stop, and permission loss all open honest gaps.
class TrackingSession {
  TrackingSession({
    required LocationTracker tracker,
    required SettingsRepository settings,
    required GapsRepository gaps,
    required RawPointsRepository points,
  })  : _tracker = tracker,
        _settings = settings,
        _gaps = gaps,
        _points = points;

  final LocationTracker _tracker;
  final SettingsRepository _settings;
  final GapsRepository _gaps;
  final RawPointsRepository _points;
  final Battery _battery = Battery();

  StreamSubscription<TrackingStatus>? _statusSub;
  StreamSubscription<BatteryState>? _batterySub;
  Timer? _batteryPoll;

  TrackingStatus _lastStatus = TrackingStatus.off;
  TrackingMode? _modeBeforeSaver;
  bool _autoSaverActive = false;
  bool _started = false;

  LocationTracker get tracker => _tracker;

  Future<void> ensureStarted() async {
    if (_started) return;
    _started = true;

    _statusSub = _tracker.status.listen(_onStatus);

    final enabled = await _settings.read(SettingKeys.trackingEnabled);
    if (enabled != 'true') return;

    final mode = await _readPreferredMode();
    await _tracker.start(mode);
    await _maybeApplyAutoSaver();
    _startBatteryWatch();
  }

  Future<TrackingMode> _readPreferredMode() async {
    final raw = await _settings.read(SettingKeys.trackingMode);
    return switch (raw) {
      'high' => TrackingMode.high,
      'saver' => TrackingMode.saver,
      _ => TrackingMode.balanced,
    };
  }

  Future<bool> _autoSaverEnabled() async {
    final raw = await _settings.read(SettingKeys.autoSaverEnabled);
    // Default on.
    return raw != 'false';
  }

  Future<int> _autoSaverLevel() async {
    final raw = await _settings.read(SettingKeys.autoSaverLevel);
    return int.tryParse(raw ?? '') ?? 20;
  }

  void _onStatus(TrackingStatus status) {
    if (status == _lastStatus) return;

    // Close gap when recording resumes.
    if (status == TrackingStatus.on) {
      unawaited(_gaps.end());
    } else if (_lastStatus == TrackingStatus.on) {
      final reason = switch (status) {
        TrackingStatus.paused => GapReason.paused,
        TrackingStatus.needsPermission => GapReason.permission,
        TrackingStatus.locationServicesOff => GapReason.permission,
        TrackingStatus.off => GapReason.off,
        TrackingStatus.on => GapReason.unknown,
      };
      _gaps.begin(reason);
    }

    _lastStatus = status;
  }

  Future<void> start(TrackingMode mode) async {
    await _settings.write(SettingKeys.trackingEnabled, 'true');
    await _settings.write(SettingKeys.trackingMode, mode.name);
    await _gaps.end();
    await _tracker.start(mode);
    _autoSaverActive = false;
    _modeBeforeSaver = null;
    await _maybeApplyAutoSaver();
    _startBatteryWatch();
  }

  Future<void> pause() async {
    await _tracker.pause();
  }

  Future<void> resume() async {
    await _tracker.resume();
    await _maybeApplyAutoSaver();
  }

  Future<void> stop() async {
    await _settings.write(SettingKeys.trackingEnabled, 'false');
    await _tracker.stop();
    await _gaps.end();
    _stopBatteryWatch();
    _autoSaverActive = false;
    _modeBeforeSaver = null;
  }

  Future<void> setMode(TrackingMode mode) async {
    await _settings.write(SettingKeys.trackingMode, mode.name);
    // User picked a mode: clear temporary saver override.
    _autoSaverActive = false;
    _modeBeforeSaver = null;
    await _tracker.setMode(mode);
  }

  void _startBatteryWatch() {
    _batteryPoll?.cancel();
    _batterySub?.cancel();
    _batteryPoll = Timer.periodic(const Duration(minutes: 2), (_) {
      unawaited(_maybeApplyAutoSaver());
    });
    try {
      _batterySub = _battery.onBatteryStateChanged.listen((_) {
        unawaited(_maybeApplyAutoSaver());
      });
    } catch (_) {
      // Some platforms lack the stream; polling still runs.
    }
  }

  void _stopBatteryWatch() {
    _batteryPoll?.cancel();
    _batteryPoll = null;
    _batterySub?.cancel();
    _batterySub = null;
  }

  Future<void> _maybeApplyAutoSaver() async {
    if (_tracker.currentStatus != TrackingStatus.on) return;
    if (!await _autoSaverEnabled()) return;

    int level;
    try {
      level = await _battery.batteryLevel;
    } catch (_) {
      return;
    }

    final threshold = await _autoSaverLevel();
    final recoverAt = threshold + 5;

    if (level <= threshold && !_autoSaverActive) {
      _modeBeforeSaver = _tracker.currentMode;
      if (_tracker.currentMode != TrackingMode.saver) {
        _autoSaverActive = true;
        await _tracker.setMode(TrackingMode.saver);
      }
    } else if (level >= recoverAt && _autoSaverActive) {
      final restore = _modeBeforeSaver ?? await _readPreferredMode();
      _autoSaverActive = false;
      _modeBeforeSaver = null;
      if (restore != TrackingMode.saver) {
        await _tracker.setMode(restore);
      }
    }
  }

  /// Health line for settings: last point age, or null if never recorded.
  Future<String?> healthLabel() async {
    final at = _tracker.lastPointAt ?? await _points.lastRecordedAt();
    if (at == null) return null;
    final age = DateTime.now().toUtc().difference(
          DateTime.fromMillisecondsSinceEpoch(at, isUtc: true),
        );
    if (age.inMinutes < 1) return 'Last point just now';
    if (age.inMinutes < 60) return 'Last point ${age.inMinutes} min ago';
    if (age.inHours < 24) return 'Last point ${age.inHours} h ago';
    return 'Last point ${age.inDays} d ago';
  }

  /// True when we expected points but none in the last 30 minutes.
  Future<bool> isStale() async {
    if (_tracker.currentStatus != TrackingStatus.on) return false;
    final at = _tracker.lastPointAt ?? await _points.lastRecordedAt();
    if (at == null) return true;
    final age = DateTime.now().toUtc().difference(
          DateTime.fromMillisecondsSinceEpoch(at, isUtc: true),
        );
    return age > const Duration(minutes: 30);
  }

  Future<void> dispose() async {
    await _statusSub?.cancel();
    _stopBatteryWatch();
  }
}
