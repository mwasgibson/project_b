import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'app_database.dart';

/// Reasons match docs/05 gaps.reason.
enum GapReason { paused, permission, off, unknown }

class GapsRepository {
  GapsRepository(this._db);

  final AppDatabase _db;
  final _uuid = const Uuid();

  int? _openStartAt;
  GapReason? _openReason;

  void begin(GapReason reason) {
    if (_openStartAt != null) return;
    _openStartAt = DateTime.now().toUtc().millisecondsSinceEpoch;
    _openReason = reason;
  }

  Future<void> end({Duration minDuration = const Duration(minutes: 1)}) async {
    final start = _openStartAt;
    final reason = _openReason;
    _openStartAt = null;
    _openReason = null;
    if (start == null || reason == null) return;

    final endAt = DateTime.now().toUtc().millisecondsSinceEpoch;
    if (endAt - start < minDuration.inMilliseconds) return;

    await _db.into(_db.gaps).insert(
          GapsCompanion.insert(
            id: _uuid.v4(),
            startAt: start,
            endAt: endAt,
            reason: Value(reason.name),
          ),
        );
  }

  Stream<List<Gap>> watchForDay(DateTime localDay) {
    final start = DateTime(localDay.year, localDay.month, localDay.day);
    final end = start.add(const Duration(days: 1));
    final startMs = start.toUtc().millisecondsSinceEpoch;
    final endMs = end.toUtc().millisecondsSinceEpoch;

    return (_db.select(_db.gaps)
          ..where(
            (t) =>
                t.startAt.isBiggerOrEqualValue(startMs) &
                t.startAt.isSmallerThanValue(endMs),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.startAt)]))
        .watch();
  }

  Future<int> countAll() async {
    final count = _db.gaps.id.count();
    final query = _db.selectOnly(_db.gaps)..addColumns([count]);
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }
}
