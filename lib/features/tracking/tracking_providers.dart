import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/gaps_repository.dart';
import '../../core/db/raw_points_repository.dart';
import '../../core/db/segmentation_repository.dart';
import '../../core/permissions/permission_providers.dart';
import '../../core/providers.dart';
import '../../core/settings/setting_keys.dart';
import '../../domain/timeline/timeline_entry.dart';
import '../../domain/tracking/location_tracker.dart';
import 'data/geolocator_location_tracker.dart';
import 'tracking_session.dart';

final rawPointsRepositoryProvider = Provider<RawPointsRepository>(
  (ref) => RawPointsRepository(ref.watch(databaseProvider)),
);

final gapsRepositoryProvider = Provider<GapsRepository>(
  (ref) => GapsRepository(ref.watch(databaseProvider)),
);

final segmentationRepositoryProvider = Provider<SegmentationRepository>(
  (ref) => SegmentationRepository(ref.watch(databaseProvider)),
);

final locationTrackerProvider = Provider<LocationTracker>((ref) {
  final tracker = GeolocatorLocationTracker(
    points: ref.watch(rawPointsRepositoryProvider),
    permissions: ref.watch(permissionServiceProvider),
  );
  ref.onDispose(tracker.dispose);
  return tracker;
});

final trackingSessionProvider = Provider<TrackingSession>((ref) {
  final session = TrackingSession(
    tracker: ref.watch(locationTrackerProvider),
    settings: ref.watch(settingsRepositoryProvider),
    gaps: ref.watch(gapsRepositoryProvider),
    points: ref.watch(rawPointsRepositoryProvider),
  );
  ref.onDispose(session.dispose);
  session.ensureStarted();
  return session;
});

final trackingStatusProvider = StreamProvider<TrackingStatus>((ref) {
  final session = ref.watch(trackingSessionProvider);
  return session.tracker.status;
});

final rawPointCountProvider = StreamProvider<int>((ref) {
  return ref.watch(rawPointsRepositoryProvider).watchCount();
});

/// Today's visits + trips, ordered. Triggers a segmenter pass once.
final todaysTimelineProvider = StreamProvider<List<TimelineEntry>>((ref) {
  final repo = ref.watch(segmentationRepositoryProvider);
  repo.runOnce();
  return repo.watchTimelineForDay(DateTime.now());
});

/// Kept for call sites that only need visits.
final todaysVisitsProvider = StreamProvider((ref) {
  final repo = ref.watch(segmentationRepositoryProvider);
  return repo.watchVisitsForDay(DateTime.now());
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

final autoSaverEnabledProvider = StreamProvider<bool>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.watch(SettingKeys.autoSaverEnabled).map((raw) => raw != 'false');
});

final autoSaverLevelProvider = StreamProvider<int>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.watch(SettingKeys.autoSaverLevel).map(
        (raw) => int.tryParse(raw ?? '') ?? 20,
      );
});

Future<void> setTrackingModeSetting(WidgetRef ref, TrackingMode mode) async {
  await ref.read(trackingSessionProvider).setMode(mode);
}

Future<void> runSegmentation(WidgetRef ref) async {
  await ref.read(segmentationRepositoryProvider).runOnce();
  ref.invalidate(todaysTimelineProvider);
  ref.invalidate(todaysVisitsProvider);
}
