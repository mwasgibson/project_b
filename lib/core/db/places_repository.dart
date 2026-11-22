import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/places/place_match.dart';
import '../../domain/places/place_resolver.dart';
import '../../domain/places/visited_place.dart';
import 'app_database.dart';

class PlacesRepository {
  PlacesRepository(this._db);

  final AppDatabase _db;
  final _uuid = const Uuid();

  static const _duplicateRadiusM = 120.0;
  static const _clusterRadiusM = 150.0;

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
    return (_db.select(_db.places)..where((t) => t.deleted.equals(false)))
        .get();
  }

  Stream<List<Place>> watchDeletedPlaces() {
    return (_db.select(_db.places)
          ..where((t) => t.deleted.equals(true))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch();
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
    final nearby = await findNearby(lat, lng);
    if (nearby != null) {
      if ((nearby.name == null || nearby.name!.trim().isEmpty) &&
          resolved.name.trim().isNotEmpty) {
        final now = DateTime.now().toUtc().millisecondsSinceEpoch;
        await (_db.update(_db.places)..where((t) => t.id.equals(nearby.id)))
            .write(
          PlacesCompanion(
            name: Value(resolved.name),
            address: Value(resolved.address),
            category: Value(resolved.category),
            updatedAt: Value(now),
          ),
        );
        return (await getById(nearby.id))!;
      }
      return nearby;
    }

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

  Future<Place> ensureUserNamedPlace({
    required String name,
    required double lat,
    required double lng,
    String? existingPlaceId,
    int radiusM = 100,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Place name must not be empty');
    }

    if (existingPlaceId != null) {
      await renameUser(id: existingPlaceId, name: trimmed);
      return (await getById(existingPlaceId))!;
    }

    final nearby = await findNearby(lat, lng);
    if (nearby != null) {
      await renameUser(id: nearby.id, name: trimmed);
      return (await getById(nearby.id))!;
    }

    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final id = _uuid.v4();
    await _db.into(_db.places).insert(
          PlacesCompanion.insert(
            id: id,
            name: Value(trimmed),
            nameSource: const Value('user'),
            lat: lat,
            lng: lng,
            radiusM: Value(radiusM),
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
        name: Value(name.trim()),
        nameSource: const Value('user'),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> softDelete(String id) async {
    await softDeleteMany([id]);
  }

  Future<void> softDeleteMany(List<String> ids) async {
    if (ids.isEmpty) return;
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    await (_db.update(_db.places)..where((t) => t.id.isIn(ids))).write(
      PlacesCompanion(
        deleted: const Value(true),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> restorePlaces(List<String> ids) async {
    if (ids.isEmpty) return;
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    await (_db.update(_db.places)..where((t) => t.id.isIn(ids))).write(
      PlacesCompanion(
        deleted: const Value(false),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> permanentlyDeletePlaces(List<String> ids) async {
    if (ids.isEmpty) return;
    await _db.transaction(() async {
      // Detach visits rather than cascade-delete history.
      await (_db.update(_db.visits)..where((t) => t.placeId.isIn(ids))).write(
        const VisitsCompanion(placeId: Value(null)),
      );
      await (_db.delete(_db.places)..where((t) => t.id.isIn(ids))).go();
    });
  }

  /// Merge place rows that are essentially the same spot; re-point visits.
  Future<int> consolidateDuplicates() async {
    final places = await allActive();
    if (places.length < 2) return 0;

    var merged = 0;
    final used = <String>{};

    places.sort((a, b) {
      final au = a.nameSource == 'user' ? 0 : 1;
      final bu = b.nameSource == 'user' ? 0 : 1;
      if (au != bu) return au.compareTo(bu);
      return b.updatedAt.compareTo(a.updatedAt);
    });

    for (var i = 0; i < places.length; i++) {
      final keep = places[i];
      if (used.contains(keep.id)) continue;

      for (var j = i + 1; j < places.length; j++) {
        final other = places[j];
        if (used.contains(other.id)) continue;
        final dist = _haversineM(keep.lat, keep.lng, other.lat, other.lng);
        if (dist > _duplicateRadiusM) continue;

        final now = DateTime.now().toUtc().millisecondsSinceEpoch;
        await _db.transaction(() async {
          await (_db.update(_db.visits)
                ..where((t) => t.placeId.equals(other.id)))
              .write(
            VisitsCompanion(
              placeId: Value(keep.id),
              updatedAt: Value(now),
            ),
          );
          await softDelete(other.id);
        });
        used.add(other.id);
        merged++;
      }
      used.add(keep.id);
    }

    return merged;
  }

  Future<List<VisitedPlace>> listVisitedPlaces() async {
    await consolidateDuplicates();

    final visits = await (_db.select(_db.visits)
          ..where((t) => t.deleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.startAt)]))
        .get();

    if (visits.isEmpty) return [];

    final places = {for (final p in await allActive()) p.id: p};

    final byPlace = <String, List<Visit>>{};
    final unlabelled = <Visit>[];

    for (final v in visits) {
      final pid = v.placeId;
      if (pid != null && places.containsKey(pid)) {
        (byPlace[pid] ??= []).add(v);
      } else {
        unlabelled.add(v);
      }
    }

    final result = <VisitedPlace>[];

    for (final entry in byPlace.entries) {
      final place = places[entry.key]!;
      final name = (place.name?.trim().isNotEmpty == true)
          ? place.name!.trim()
          : 'Unknown place';
      result.add(
        VisitedPlace(
          key: place.id,
          placeId: place.id,
          name: name,
          address: place.address,
          nameSource: place.nameSource,
          lat: place.lat,
          lng: place.lng,
          visits: entry.value,
        ),
      );
    }

    final remaining = [...unlabelled];
    while (remaining.isNotEmpty) {
      final seed = remaining.removeAt(0);
      final cluster = <Visit>[seed];
      remaining.removeWhere((v) {
        final d = _haversineM(seed.lat, seed.lng, v.lat, v.lng);
        if (d <= _clusterRadiusM) {
          cluster.add(v);
          return true;
        }
        return false;
      });
      cluster.sort((a, b) => b.startAt.compareTo(a.startAt));
      final lat =
          cluster.map((v) => v.lat).reduce((a, b) => a + b) / cluster.length;
      final lng =
          cluster.map((v) => v.lng).reduce((a, b) => a + b) / cluster.length;
      result.add(
        VisitedPlace(
          key: 'geo:${lat.toStringAsFixed(4)},${lng.toStringAsFixed(4)}',
          name: 'Unknown place',
          lat: lat,
          lng: lng,
          visits: cluster,
        ),
      );
    }

    result.sort((a, b) => b.lastVisitAt.compareTo(a.lastVisitAt));
    return result;
  }

  Future<VisitedPlace?> getVisitedPlace(String key) async {
    final all = await listVisitedPlaces();
    for (final p in all) {
      if (p.key == key) return p;
    }
    return null;
  }

  static double _haversineM(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const r = 6371000.0;
    final p1 = lat1 * math.pi / 180;
    final p2 = lat2 * math.pi / 180;
    final dp = (lat2 - lat1) * math.pi / 180;
    final dl = (lng2 - lng1) * math.pi / 180;
    final a = math.sin(dp / 2) * math.sin(dp / 2) +
        math.cos(p1) * math.cos(p2) * math.sin(dl / 2) * math.sin(dl / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }
}
