import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/raw_points_repository.dart';
import '../../core/permissions/permission_providers.dart';
import '../../core/providers.dart';
import '../../core/settings/setting_keys.dart';
import '../../domain/tracking/location_tracker.dart';
import 'data/geolocator_location_tracker.dart';

final rawPointsRepositoryProvider = Provider<RawPointsRepository>(
  (ref) => RawPointsRepository(ref.watch(databaseProvider)),
);

final locationTrackerProvider = Provider<LocationTracker>((ref) {
  final tracker = GeolocatorLocationTracker(
    points: ref.watch(rawPointsRepositoryProvider),
    permissions: ref.watch(permissionServiceProvider),
  );
  ref.onDispose(() {
    // ignore: avoid_dynamic_calls
    (tracker).dispose();
  });
  return tracker;
});

final trackingStatusProvider = StreamProvider<TrackingStatus>((ref) {
  final tracker = ref.watch(locationTrackerProvider);
  return tracker.status;
});

final rawPointCountProvider = StreamProvider<int>((ref) {
  return ref.watch(rawPointsRepositoryProvider).watchCount();
});

final trackingModeSettingProvider = StreamProvider<TrackingMode>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.watch(SettingKeys.trackingMode).map((raw) {
    return switch (raw) {
      'high' => TrackingMode.high,
      'saver' => TrackingMode.saver,
      _ => TrackingMode.balanced,
    };
  });
});

Future<void> setTrackingModeSetting(WidgetRef ref, TrackingMode mode) async {
  await ref
      .read(settingsRepositoryProvider)
      .write(SettingKeys.trackingMode, mode.name);
  await ref.read(locationTrackerProvider).setMode(mode);
}
