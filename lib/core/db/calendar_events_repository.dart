import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'app_database.dart';

class CalendarEventsRepository {
  CalendarEventsRepository(this._db);

  final AppDatabase _db;
  final _uuid = const Uuid();

  Future<CalendarEvent?> getById(String id) {
    final q = _db.select(_db.calendarEvents)
      ..where((t) => t.id.equals(id) & t.deleted.equals(false));
    return q.getSingleOrNull();
  }

  Stream<List<CalendarEvent>> watchForDay(DateTime localDay) {
    final (startMs, endMs) = _dayBounds(localDay);
    return (_db.select(_db.calendarEvents)
          ..where(
            (t) =>
                t.deleted.equals(false) &
                // Event overlaps the local day.
                t.startAt.isSmallerThanValue(endMs) &
                t.endAt.isBiggerThanValue(startMs),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.startAt)]))
        .watch();
  }

  /// Days in [month] (local) that have at least one event (for month dots).
  Stream<Set<int>> watchEventDaysInMonth(DateTime month) {
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);
    final startMs = start.toUtc().millisecondsSinceEpoch;
    final endMs = end.toUtc().millisecondsSinceEpoch;

    return (_db.select(_db.calendarEvents)
          ..where(
            (t) =>
                t.deleted.equals(false) &
                t.startAt.isSmallerThanValue(endMs) &
                t.endAt.isBiggerThanValue(startMs),
          ))
        .watch()
        .map((rows) {
      final days = <int>{};
      for (final e in rows) {
        final local = DateTime.fromMillisecondsSinceEpoch(
          e.startAt,
          isUtc: true,
        ).toLocal();
        if (local.year == month.year && local.month == month.month) {
          days.add(local.day);
        }
      }
      return days;
    });
  }

  Future<CalendarEvent> create({
    required String title,
    required int startAt,
    required int endAt,
    required int utcOffsetMin,
    bool allDay = false,
    String? notes,
    String? locationText,
  }) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final id = _uuid.v4();
    await _db.into(_db.calendarEvents).insert(
          CalendarEventsCompanion.insert(
            id: id,
            title: title.trim(),
            notes: Value(notes?.trim().isEmpty == true ? null : notes?.trim()),
            startAt: startAt,
            endAt: endAt,
            allDay: Value(allDay),
            utcOffsetMin: utcOffsetMin,
            locationText: Value(
              locationText?.trim().isEmpty == true
                  ? null
                  : locationText?.trim(),
            ),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return (await getById(id))!;
  }

  Future<void> update({
    required String id,
    required String title,
    required int startAt,
    required int endAt,
    required int utcOffsetMin,
    bool allDay = false,
    String? notes,
    String? locationText,
  }) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    await (_db.update(_db.calendarEvents)..where((t) => t.id.equals(id))).write(
          CalendarEventsCompanion(
            title: Value(title.trim()),
            notes: Value(notes?.trim().isEmpty == true ? null : notes?.trim()),
            startAt: Value(startAt),
            endAt: Value(endAt),
            allDay: Value(allDay),
            utcOffsetMin: Value(utcOffsetMin),
            locationText: Value(
              locationText?.trim().isEmpty == true
                  ? null
                  : locationText?.trim(),
            ),
            updatedAt: Value(now),
          ),
        );
  }

  Future<void> softDelete(String id) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    await (_db.update(_db.calendarEvents)..where((t) => t.id.equals(id))).write(
          CalendarEventsCompanion(
            deleted: const Value(true),
            updatedAt: Value(now),
          ),
        );
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
