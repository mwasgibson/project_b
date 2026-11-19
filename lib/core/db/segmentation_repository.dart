import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/segmentation/segmenter.dart';
import '../../domain/timeline/timeline_entry.dart';
import 'app_database.dart';

class SegmentationRunResult {
  const SegmentationRunResult({
    required this.visitsCreated,
    required this.tripsCreated,
    required this.unprocessedBefore,
    required this.pointsConsumed,
  });

  final int visitsCreated;
  final int tripsCreated;
  final int unprocessedBefore;
  final int pointsConsumed;
}

class SegmentationRepository {
  SegmentationRepository(this._db, {Segmenter? segmenter})
      : _segmenter = segmenter ?? const Segmenter();

  final AppDatabase _db;
  final Segmenter _segmenter;
  final _uuid = const Uuid();

  /// Run segmenter on unprocessed points and persist visits/trips.
  ///
  /// [manual] uses relaxed thresholds (user tapped Find visits / refresh).
  Future<SegmentationRunResult> runOnce({bool manual = false}) async {
    final unprocessed = await (_db.select(_db.rawPoints)
          ..where((t) => t.processed.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.recordedAt)]))
        .get();

    if (unprocessed.isEmpty) {
      return const SegmentationRunResult(
        visitsCreated: 0,
        tripsCreated: 0,
        unprocessedBefore: 0,
        pointsConsumed: 0,
      );
    }

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

    final segmenter = manual
        ? const Segmenter(config: SegmenterConfig.manual)
        : _segmenter;
    final result = segmenter.run(inputs);

    if (result.visits.isEmpty) {
      return SegmentationRunResult(
        visitsCreated: 0,
        tripsCreated: 0,
        unprocessedBefore: unprocessed.length,
        pointsConsumed: 0,
      );
    }

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

    return SegmentationRunResult(
      visitsCreated: result.visits.length,
      tripsCreated: result.trips.length,
      unprocessedBefore: unprocessed.length,
      pointsConsumed: result.processedPointIds.length,
    );
  }

  Stream<List<Visit>> watchVisitsForDay(DateTime localDay) {
    final (startMs, endMs) = _dayBounds(localDay);

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

  Stream<List<Trip>> watchTripsForDay(DateTime localDay) {
    final (startMs, endMs) = _dayBounds(localDay);

    return (_db.select(_db.trips)
          ..where(
            (t) =>
                t.deleted.equals(false) &
                t.startAt.isBiggerOrEqualValue(startMs) &
                t.startAt.isSmallerThanValue(endMs),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.startAt)]))
        .watch();
  }

  Stream<Set<int>> watchVisitDaysInMonth(DateTime month) {
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);
    final startMs = start.toUtc().millisecondsSinceEpoch;
    final endMs = end.toUtc().millisecondsSinceEpoch;

    return (_db.select(_db.visits)
          ..where(
            (t) =>
                t.deleted.equals(false) &
                t.startAt.isBiggerOrEqualValue(startMs) &
                t.startAt.isSmallerThanValue(endMs),
          ))
        .watch()
        .map((rows) {
      final days = <int>{};
      for (final v in rows) {
        final local = DateTime.fromMillisecondsSinceEpoch(
          v.startAt,
          isUtc: true,
        ).toLocal();
        if (local.year == month.year && local.month == month.month) {
          days.add(local.day);
        }
      }
      return days;
    });
  }

  Stream<List<TimelineEntry>> watchTimelineForDay(DateTime localDay) {
    return watchVisitsForDay(localDay).asyncExpand((visits) {
      return watchTripsForDay(localDay).map((trips) {
        final entries = <TimelineEntry>[
          for (final v in visits) TimelineEntry.visit(v),
          for (final t in trips) TimelineEntry.trip(t),
        ]..sort((a, b) => a.sortAt.compareTo(b.sortAt));
        return entries;
      });
    });
  }

  Future<Visit?> getVisit(String id) async {
    final query = _db.select(_db.visits)
      ..where((t) => t.id.equals(id) & t.deleted.equals(false));
    return query.getSingleOrNull();
  }

  Future<void> attachPlace({
    required String visitId,
    required String placeId,
  }) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    await (_db.update(_db.visits)..where((t) => t.id.equals(visitId))).write(
          VisitsCompanion(
            placeId: Value(placeId),
            labelState: const Value('done'),
            userEdited: const Value(true),
            updatedAt: Value(now),
          ),
        );
  }

  Future<void> softDeleteVisit(String id) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    await (_db.update(_db.visits)..where((t) => t.id.equals(id))).write(
          VisitsCompanion(
            deleted: const Value(true),
            updatedAt: Value(now),
          ),
        );
    await (_db.update(_db.trips)
          ..where(
            (t) => t.fromVisitId.equals(id) | t.toVisitId.equals(id),
          ))
        .write(
      TripsCompanion(
        deleted: const Value(true),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> adjustVisitTimes({
    required String id,
    required int startAt,
    int? endAt,
  }) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    await (_db.update(_db.visits)..where((t) => t.id.equals(id))).write(
          VisitsCompanion(
            startAt: Value(startAt),
            endAt: Value(endAt),
            userEdited: const Value(true),
            updatedAt: Value(now),
          ),
        );
  }

  Stream<int> watchVisitCount() {
    final count = _db.visits.id.count();
    final query = _db.selectOnly(_db.visits)
      ..addColumns([count])
      ..where(_db.visits.deleted.equals(false));
    return query.watchSingle().map((row) => row.read(count) ?? 0);
  }

  (int, int) _dayBounds(DateTime localDay) {
    final start = DateTime(localDay.year, localDay.month, localDay.day);
    final end = start.add(const Duration(days: 1));
    return (
      start.toUtc().millisecondsSinceEpoch,
      end.toUtc().millisecondsSinceEpoch,
    );
  }
}
