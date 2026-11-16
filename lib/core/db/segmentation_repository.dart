import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/segmentation/segmenter.dart';
import 'app_database.dart';

class SegmentationRepository {
  SegmentationRepository(this._db, {Segmenter? segmenter})
      : _segmenter = segmenter ?? const Segmenter();

  final AppDatabase _db;
  final Segmenter _segmenter;
  final _uuid = const Uuid();

  /// Run segmenter on unprocessed points and persist visits/trips.
  /// Returns number of new visits written.
  Future<int> runOnce() async {
    final unprocessed = await (_db.select(_db.rawPoints)
          ..where((t) => t.processed.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.recordedAt)]))
        .get();

    if (unprocessed.isEmpty) return 0;

    final inputs = unprocessed
        .map(
          (p) => PointInput(
            id: p.id,
            recordedAt: p.recordedAt,
            utcOffsetMin: p.utcOffsetMin,
            lat: p.lat,
            lng: p.lng,
          ),
        )
        .toList();

    final result = _segmenter.run(inputs);
    if (result.visits.isEmpty) return 0;

    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final visitIds = <String>[];

    await _db.transaction(() async {
      for (final v in result.visits) {
        final id = _uuid.v4();
        visitIds.add(id);
        await _db.into(_db.visits).insert(
              VisitsCompanion.insert(
                id: id,
                startAt: v.startAt,
                endAt: Value(v.endAt),
                utcOffsetMin: v.utcOffsetMin,
                lat: v.lat,
                lng: v.lng,
                pointCount: Value(v.pointCount),
                createdAt: now,
                updatedAt: now,
              ),
            );
      }

      for (final t in result.trips) {
        await _db.into(_db.trips).insert(
              TripsCompanion.insert(
                id: _uuid.v4(),
                fromVisitId: Value(visitIds[t.fromVisitIndex]),
                toVisitId: Value(visitIds[t.toVisitIndex]),
                startAt: t.startAt,
                endAt: t.endAt,
                utcOffsetMin: t.utcOffsetMin,
                distanceM: Value(t.distanceM),
                createdAt: now,
                updatedAt: now,
              ),
            );
      }

      for (final id in result.processedPointIds) {
        await (_db.update(_db.rawPoints)..where((t) => t.id.equals(id))).write(
              const RawPointsCompanion(processed: Value(true)),
            );
      }
    });

    return result.visits.length;
  }

  Stream<List<Visit>> watchVisitsForDay(DateTime localDay) {
    final start = DateTime(localDay.year, localDay.month, localDay.day);
    final end = start.add(const Duration(days: 1));
    final startMs = start.toUtc().millisecondsSinceEpoch;
    final endMs = end.toUtc().millisecondsSinceEpoch;

    return (_db.select(_db.visits)
          ..where(
            (t) =>
                t.deleted.equals(false) &
                t.startAt.isBiggerOrEqualValue(startMs) &
                t.startAt.isSmallerThanValue(endMs),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.startAt)]))
        .watch();
  }

  Stream<int> watchVisitCount() {
    final count = _db.visits.id.count();
    final query = _db.selectOnly(_db.visits)
      ..addColumns([count])
      ..where(_db.visits.deleted.equals(false));
    return query.watchSingle().map((row) => row.read(count) ?? 0);
  }
}
