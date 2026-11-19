import 'dart:math' as math;

import 'package:drift/drift.dart';

import '../../domain/tracking/location_tracker.dart';
import 'app_database.dart';

class RawPointsRepository {
  RawPointsRepository(this._db);

  final AppDatabase _db;

  /// Insert unless nearly identical to the last point (same spot / short gap).
  /// Returns the new row id, or 0 if skipped as a duplicate.
  Future<int> insertSample(LocationSample sample) async {
    final last = await lastSample();
    if (last != null) {
      final dt = sample.recordedAt - last.recordedAt;
      final dist = _haversineM(last.lat, last.lng, sample.lat, sample.lng);
      // Stay put: ignore noise within ~25 m for two minutes.
      if (dt >= 0 && dt < 2 * 60 * 1000 && dist < 25) {
        return 0;
      }
    }

    return _db.into(_db.rawPoints).insert(
          RawPointsCompanion.insert(
            recordedAt: sample.recordedAt,
            utcOffsetMin: sample.utcOffsetMin,
            lat: sample.lat,
            lng: sample.lng,
            accuracyM: Value(sample.accuracyM),
            speedMps: Value(sample.speedMps),
            altitudeM: Value(sample.altitudeM),
            activity: Value(sample.activity),
            batteryPct: Value(sample.batteryPct),
            mode: sample.mode.name,
          ),
        );
  }

  Future<int> countAll() async {
    final count = _db.rawPoints.id.count();
    final query = _db.selectOnly(_db.rawPoints)..addColumns([count]);
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Stream<int> watchCount() {
    final count = _db.rawPoints.id.count();
    final query = _db.selectOnly(_db.rawPoints)..addColumns([count]);
    return query.watchSingle().map((row) => row.read(count) ?? 0);
  }

  Future<int?> lastRecordedAt() async {
    final query = _db.select(_db.rawPoints)
      ..orderBy([(t) => OrderingTerm.desc(t.recordedAt)])
      ..limit(1);
    final row = await query.getSingleOrNull();
    return row?.recordedAt;
  }

  Future<RawPoint?> lastSample() async {
    final query = _db.select(_db.rawPoints)
      ..orderBy([(t) => OrderingTerm.desc(t.recordedAt)])
      ..limit(1);
    return query.getSingleOrNull();
  }

  Stream<List<RawPoint>> watchRecent({int limit = 200}) {
    final query = _db.select(_db.rawPoints)
      ..orderBy([(t) => OrderingTerm.desc(t.recordedAt)])
      ..limit(limit);
    return query.watch();
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
