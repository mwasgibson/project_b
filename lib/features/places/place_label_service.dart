import 'package:drift/drift.dart';

import '../../core/db/app_database.dart';
import '../../core/db/places_repository.dart';
import '../../core/settings/setting_keys.dart';
import '../../core/settings/settings_repository.dart';
import '../../domain/places/place_resolver.dart';

/// Labels pending visits: local place match first, then [PlaceResolver].
class PlaceLabelService {
  PlaceLabelService({
    required AppDatabase db,
    required PlacesRepository places,
    required PlaceResolver resolver,
    required SettingsRepository settings,
  })  : _db = db,
        _places = places,
        _resolver = resolver,
        _settings = settings;

  final AppDatabase _db;
  final PlacesRepository _places;
  final PlaceResolver _resolver;
  final SettingsRepository _settings;

  Future<bool> _autoLabelEnabled() async {
    final raw = await _settings.read(SettingKeys.autoLabelEnabled);
    // Default on.
    return raw != 'false';
  }

  /// Process up to [limit] pending visits. Returns how many reached `done`.
  Future<int> processPending({int limit = 20}) async {
    final enabled = await _autoLabelEnabled();
    if (!enabled) {
      await _markAllPendingDisabled();
      return 0;
    }

    final pending = await (_db.select(_db.visits)
          ..where(
            (t) =>
                t.deleted.equals(false) &
                t.labelState.equals('pending') &
                t.userEdited.equals(false),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.startAt)])
          ..limit(limit))
        .get();

    var done = 0;
    for (final visit in pending) {
      final ok = await _labelOne(visit);
      if (ok) done++;
    }
    return done;
  }

  Future<void> _markAllPendingDisabled() async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    await (_db.update(_db.visits)
          ..where(
            (t) => t.labelState.equals('pending') & t.deleted.equals(false),
          ))
        .write(
      VisitsCompanion(
        labelState: const Value('disabled'),
        updatedAt: Value(now),
      ),
    );
  }

  Future<bool> _labelOne(Visit visit) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;

    // 1) Reuse an existing place within radius — no network.
    final nearby = await _places.findNearby(visit.lat, visit.lng);
    if (nearby != null) {
      await (_db.update(_db.visits)..where((t) => t.id.equals(visit.id))).write(
            VisitsCompanion(
              placeId: Value(nearby.id),
              labelState: const Value('done'),
              updatedAt: Value(now),
            ),
          );
      return true;
    }

    // 2) Reverse geocode.
    try {
      final resolved = await _resolver.resolve(visit.lat, visit.lng);
      final place = await _places.insertFromResolved(
        lat: visit.lat,
        lng: visit.lng,
        resolved: resolved,
      );
      await (_db.update(_db.visits)..where((t) => t.id.equals(visit.id))).write(
            VisitsCompanion(
              placeId: Value(place.id),
              labelState: const Value('done'),
              updatedAt: Value(now),
            ),
          );
      return true;
    } on PlaceResolveException catch (e) {
      final state = switch (e.failure) {
        PlaceResolveFailure.disabled => 'disabled',
        PlaceResolveFailure.notFound => 'failed',
        PlaceResolveFailure.unavailable => 'failed',
        PlaceResolveFailure.transient => 'pending', // retry later
      };
      await (_db.update(_db.visits)..where((t) => t.id.equals(visit.id))).write(
            VisitsCompanion(
              labelState: Value(state),
              updatedAt: Value(now),
            ),
          );
      return false;
    } catch (_) {
      await (_db.update(_db.visits)..where((t) => t.id.equals(visit.id))).write(
            VisitsCompanion(
              labelState: const Value('pending'),
              updatedAt: Value(now),
            ),
          );
      return false;
    }
  }

  /// Force one visit through the queue (e.g. pull-to-refresh / retry).
  Future<void> relabelVisit(String visitId) async {
    final visit = await (_db.select(_db.visits)
          ..where((t) => t.id.equals(visitId) & t.deleted.equals(false)))
        .getSingleOrNull();
    if (visit == null) return;
    if (visit.userEdited) return;

    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    await (_db.update(_db.visits)..where((t) => t.id.equals(visitId))).write(
          VisitsCompanion(
            labelState: const Value('pending'),
            placeId: const Value(null),
            updatedAt: Value(now),
          ),
        );
    await processPending(limit: 1);
  }
}
