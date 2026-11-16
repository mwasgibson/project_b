import 'package:uuid/uuid.dart';

import 'app_database.dart';

/// Reasons match docs/05 gaps.reason.
enum GapReason { paused, permission, off, unknown }

class GapsRepository {
  GapsRepository(this._db);

  final AppDatabase _db;
  final _uuid = const Uuid();

  /// Open gap start time while tracking is interrupted, or null.
  int? _openStartAt;
  GapReason? _openReason;

  /// Begin a gap if one is not already open.
  void begin(GapReason reason) {
    if (_openStartAt != null) return;
    _openStartAt = DateTime.now().toUtc().millisecondsSinceEpoch;
    _openReason = reason;
  }

  /// Close an open gap if it lasted at least [minDuration].
  Future<void> end({Duration minDuration = const Duration(minutes: 1)}) async {
    final start = _openStartAt;
    final reason = _openReason;
    _openStartAt = null;
    _openReason = null;
    if (start == null || reason == null) return;

    final end = DateTime.now().toUtc().millisecondsSinceEpoch;
    if (end - start < minDuration.inMilliseconds) return;

    await _db.into(_db.gaps).insert(
          GapsCompanion.insert(
            id: _uuid.v4(),
            startAt: start,
            endAt: end,
            reason: reason.name,
          ),
        );
  }

  Future<int> countAll() async {
    final count = _db.gaps.id.count();
    final query = _db.selectOnly(_db.gaps)..addColumns([count]);
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }
}
