import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/places/place_match.dart';
import '../../domain/places/place_resolver.dart';
import 'app_database.dart';

class PlacesRepository {
  PlacesRepository(this._db);

  final AppDatabase _db;
  final _uuid = const Uuid();

  Future<Place?> getById(String id) {
    final q = _db.select(_db.places)
      ..where((t) => t.id.equals(id) & t.deleted.equals(false));
    return q.getSingleOrNull();
  }

  Stream<Place?> watchById(String id) {
    final q = _db.select(_db.places)
      ..where((t) => t.id.equals(id) & t.deleted.equals(false));
    return q.watchSingleOrNull();
  }

  Future<List<Place>> allActive() {
    return (_db.select(_db.places)..where((t) => t.deleted.equals(false))).get();
  }

  /// Nearest non-deleted place within its own radius (default 100 m).
  Future<Place?> findNearby(double lat, double lng) async {
    final places = await allActive();
    return PlaceMatch.nearestWithin(
      lat: lat,
      lng: lng,
      candidates: places,
      candidateLat: (p) => p.lat,
      candidateLng: (p) => p.lng,
      candidateRadiusM: (p) => p.radiusM,
    );
  }

  Future<Place> insertFromResolved({
    required double lat,
    required double lng,
    required ResolvedPlace resolved,
    int radiusM = 100,
  }) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final id = _uuid.v4();
    await _db.into(_db.places).insert(
          PlacesCompanion.insert(
            id: id,
            name: Value(resolved.name),
            nameSource: const Value('auto'),
            address: Value(resolved.address),
            lat: lat,
            lng: lng,
            radiusM: Value(radiusM),
            category: Value(resolved.category),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return (await getById(id))!;
  }

  Future<void> renameUser({
    required String id,
    required String name,
  }) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    await (_db.update(_db.places)..where((t) => t.id.equals(id))).write(
          PlacesCompanion(
            name: Value(name),
            nameSource: const Value('user'),
            updatedAt: Value(now),
          ),
        );
  }
}
