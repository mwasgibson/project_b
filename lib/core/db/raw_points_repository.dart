import 'package:drift/drift.dart';

import '../../domain/tracking/location_tracker.dart';
import 'app_database.dart';

class RawPointsRepository {
  RawPointsRepository(this._db);

  final AppDatabase _db;

  Future<int> insertSample(LocationSample sample) {
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

  Stream<List<RawPoint>> watchRecent({int limit = 50}) {
    final query = _db.select(_db.rawPoints)
      ..orderBy([(t) => OrderingTerm.desc(t.recordedAt)])
      ..limit(limit);
    return query.watch();
  }
}
