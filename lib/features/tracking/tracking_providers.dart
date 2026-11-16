import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/gaps_repository.dart';
import '../../core/db/places_repository.dart';
import '../../core/db/raw_points_repository.dart';
import '../../core/db/segmentation_repository.dart';
import '../../core/permissions/permission_providers.dart';
import '../../core/providers.dart';
import '../../core/settings/setting_keys.dart';
import '../../domain/places/place_resolver.dart';
import '../../domain/timeline/timeline_entry.dart';
import '../../domain/tracking/location_tracker.dart';
import '../places/data/platform_place_resolver.dart';
import '../places/place_label_service.dart';
import 'data/geolocator_location_tracker.dart';
import 'tracking_session.dart';

final rawPointsRepositoryProvider = Provider<RawPointsRepository>(
  (ref) => RawPointsRepository(ref.watch(databaseProvider)),
);

final gapsRepositoryProvider = Provider<GapsRepository>(
  (ref) => GapsRepository(ref.watch(databaseProvider)),
);

final placesRepositoryProvider = Provider<PlacesRepository>(
  (ref) => PlacesRepository(ref.watch(databaseProvider)),
);

final segmentationRepositoryProvider = Provider<SegmentationRepository>(
  (ref) => SegmentationRepository(ref.watch(databaseProvider)),
);

/// Swap this implementation for offline or Google Places without UI changes.
final placeResolverProvider = Provider<PlaceResolver>(
  (ref) => PlatformPlaceResolver(),
);

final placeLabelServiceProvider = Provider<PlaceLabelService>((ref) {
  return PlaceLabelService(
    db: ref.watch(databaseProvider),
    places: ref.watch(placesRepositoryProvider),
    resolver: ref.watch(placeResolverProvider),
    settings: ref.watch(settingsRepositoryProvider),
  );
});

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

/// Map of placeId → Place for today's labelled visits.
final placesByIdProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final places = await ref.watch(placesRepositoryProvider).allActive();
  return {for (final p in places) p.id: p};
});

/// Today's visits + trips, ordered. Runs segmenter then label pass.
final todaysTimelineProvider = StreamProvider<List<TimelineEntry>>((ref) {
  final repo = ref.watch(segmentationRepositoryProvider);
  final labels = ref.watch(placeLabelServiceProvider);
  () async {
    await repo.runOnce();
    await labels.processPending();
    ref.invalidate(placesByIdProvider);
  }();
  return repo.watchTimelineForDay(DateTime.now());
});

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

final autoLabelEnabledProvider = StreamProvider<bool>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.watch(SettingKeys.autoLabelEnabled).map((raw) => raw != 'false');
});

Future<void> setTrackingModeSetting(WidgetRef ref, TrackingMode mode) async {
  await ref.read(trackingSessionProvider).setMode(mode);
}

Future<void> runSegmentation(WidgetRef ref) async {
  await ref.read(segmentationRepositoryProvider).runOnce();
  await ref.read(placeLabelServiceProvider).processPending();
  ref.invalidate(todaysTimelineProvider);
  ref.invalidate(todaysVisitsProvider);
  ref.invalidate(placesByIdProvider);
}
