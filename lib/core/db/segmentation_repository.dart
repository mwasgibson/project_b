import 'dart:math' as math;

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
    this.visitsMerged = 0,
  });

  final int visitsCreated;
  final int tripsCreated;
  final int unprocessedBefore;
  final int pointsConsumed;
  final int visitsMerged;
}

class SegmentationRepository {
  SegmentationRepository(this._db, {Segmenter? segmenter})
      : _segmenter = segmenter ?? const Segmenter();

  final AppDatabase _db;
  final Segmenter _segmenter;
  final _uuid = const Uuid();

  /// Continuous stay at one location — GPS jitter and re-labelling still one visit.
  static const _mergeRadiusM = 300.0;
  static const _mergeMaxGap = Duration(hours: 24);

  Future<SegmentationRunResult> runOnce({bool manual = false}) async {
    final unprocessed = await (_db.select(_db.rawPoints)
          ..where((t) => t.processed.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.recordedAt)]))
        .get();

    if (unprocessed.isEmpty) {
      final merged = await mergeNearbyVisits();
      return SegmentationRunResult(
        visitsCreated: 0,
        tripsCreated: 0,
        unprocessedBefore: 0,
        pointsConsumed: 0,
        visitsMerged: merged,
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
      final merged = await mergeNearbyVisits();
      return SegmentationRunResult(
        visitsCreated: 0,
        tripsCreated: 0,
        unprocessedBefore: unprocessed.length,
        pointsConsumed: 0,
        visitsMerged: merged,
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

    final merged = await mergeNearbyVisits();

    return SegmentationRunResult(
      visitsCreated: result.visits.length,
      tripsCreated: result.trips.length,
      unprocessedBefore: unprocessed.length,
      pointsConsumed: result.processedPointIds.length,
      visitsMerged: merged,
    );
  }

  /// Collapse fragmented / overlapping stays at the same location into one visit.
  Future<int> mergeNearbyVisits() async {
    var totalMerged = 0;

    final placeRows = await (_db.select(_db.places)
          ..where((t) => t.deleted.equals(false)))
        .get();
    final placeName = <String, String>{
      for (final p in placeRows)
        if (p.name != null && p.name!.trim().isNotEmpty)
          p.id: p.name!.trim().toLowerCase(),
    };

    while (true) {
      final visits = await (_db.select(_db.visits)
            ..where((t) => t.deleted.equals(false))
            ..orderBy([(t) => OrderingTerm.asc(t.startAt)]))
          .get();

      if (visits.length < 2) break;

      var mergedThisPass = false;

      for (var i = 0; i < visits.length - 1; i++) {
        final a = visits[i];
        final b = visits[i + 1];
        final aEnd = a.endAt ?? a.startAt;
        final bEnd = b.endAt ?? b.startAt;
        // Negative gap = overlapping windows (common with batch segmentation).
        final gap = b.startAt - aEnd;
        final dist = _haversineM(a.lat, a.lng, b.lat, b.lng);

        final samePlaceId = a.placeId != null &&
            b.placeId != null &&
            a.placeId == b.placeId;
        final nameA =
            a.placeId == null ? null : placeName[a.placeId!];
        final nameB =
            b.placeId == null ? null : placeName[b.placeId!];
        final sameName = nameA != null && nameB != null && nameA == nameB;

        final spatialOk =
            dist <= _mergeRadiusM || samePlaceId || sameName;
        // Allow overlap (gap < 0) and gaps up to 24h at the same place.
        final temporalOk = gap <= _mergeMaxGap.inMilliseconds;

        final canMerge =
            spatialOk && temporalOk && !a.userEdited && !b.userEdited;

        if (!canMerge) continue;

        final now = DateTime.now().toUtc().millisecondsSinceEpoch;
        final newStart = math.min(a.startAt, b.startAt);
        final newEnd = math.max(aEnd, bEnd);
        final pts = (a.pointCount ?? 0) + (b.pointCount ?? 0);

        // Prefer a real place name over a plus-code style id when choosing placeId.
        final placeId = _preferPlaceId(
          a.placeId,
          b.placeId,
          placeName,
        );

        await _db.transaction(() async {
          await (_db.update(_db.visits)..where((t) => t.id.equals(a.id))).write(
                VisitsCompanion(
                  startAt: Value(newStart),
                  endAt: Value(newEnd),
                  lat: Value((a.lat + b.lat) / 2),
                  lng: Value((a.lng + b.lng) / 2),
                  pointCount: Value(pts),
                  placeId: Value(placeId),
                  updatedAt: Value(now),
                ),
              );

          await (_db.update(_db.visits)..where((t) => t.id.equals(b.id))).write(
                VisitsCompanion(
                  deleted: const Value(true),
                  updatedAt: Value(now),
                ),
              );

          // Drop trips that only linked the fragments of the same stay.
          await (_db.update(_db.trips)
                ..where(
                  (t) =>
                      t.fromVisitId.equals(b.id) |
                      t.toVisitId.equals(b.id) |
                      (t.fromVisitId.equals(a.id) & t.toVisitId.equals(b.id)) |
                      (t.fromVisitId.equals(b.id) & t.toVisitId.equals(a.id)),
                ))
              .write(
            TripsCompanion(
              deleted: const Value(true),
              updatedAt: Value(now),
            ),
          );
        });

        totalMerged++;
        mergedThisPass = true;
        break;
      }

      if (!mergedThisPass) break;
    }

    return totalMerged;
  }

  /// Prefer place with a human name over plus-code / empty labels.
  static String? _preferPlaceId(
    String? a,
    String? b,
    Map<String, String> names,
  ) {
    if (a == null) return b;
    if (b == null) return a;
    final na = names[a];
    final nb = names[b];
    final aPlus = na == null || _looksLikePlusCode(na);
    final bPlus = nb == null || _looksLikePlusCode(nb);
    if (aPlus && !bPlus) return b;
    if (bPlus && !aPlus) return a;
    return a;
  }

  static bool _looksLikePlusCode(String name) {
    // e.g. QPG2+5WX — short Open Location Code fragments from geocoders.
    final n = name.trim();
    if (n.length < 6 || n.length > 12) return false;
    return RegExp(r'^[A-Z0-9]+\+[A-Z0-9]+$', caseSensitive: false).hasMatch(n);
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

  Stream<List<TimelineEntry>> watchTimelineForDay(
    DateTime localDay, {
    required Stream<List<Gap>> gapsStream,
  }) {
    return watchVisitsForDay(localDay).asyncExpand((visits) {
      return watchTripsForDay(localDay).asyncExpand((trips) {
        return gapsStream.map((gaps) {
          final entries = <TimelineEntry>[
            for (final v in visits) TimelineEntry.visit(v),
            for (final t in trips) TimelineEntry.trip(t),
            for (final g in gaps) TimelineEntry.gap(g),
          ]..sort((a, b) => a.sortAt.compareTo(b.sortAt));
          return entries;
        });
      });
    });
  }

  Future<Visit?> getVisit(String id) async {
    final query = _db.select(_db.visits)..where((t) => t.id.equals(id));
    return query.getSingleOrNull();
  }

  Stream<List<Visit>> watchDeletedVisits() {
    return (_db.select(_db.visits)
          ..where((t) => t.deleted.equals(true))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch();
  }

  Future<void> restoreVisit(String id) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    await (_db.update(_db.visits)..where((t) => t.id.equals(id))).write(
          VisitsCompanion(
            deleted: const Value(false),
            updatedAt: Value(now),
          ),
        );
  }

  Future<void> permanentlyDeleteVisit(String id) async {
    await (_db.delete(_db.trips)
          ..where((t) => t.fromVisitId.equals(id) | t.toVisitId.equals(id)))
        .go();
    await (_db.delete(_db.visits)..where((t) => t.id.equals(id))).go();
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
