import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'app_database.dart';

class RemindersRepository {
  RemindersRepository(this._db);

  final AppDatabase _db;
  final _uuid = const Uuid();

  Future<Reminder?> forEvent(String eventId) {
    final q = _db.select(_db.reminders)
      ..where(
        (t) =>
            t.eventId.equals(eventId) &
            t.deleted.equals(false) &
            t.status.equals('scheduled'),
      )
      ..limit(1);
    return q.getSingleOrNull();
  }

  Future<List<Reminder>> allScheduled() {
    return (_db.select(_db.reminders)
          ..where(
            (t) => t.deleted.equals(false) & t.status.equals('scheduled'),
          ))
        .get();
  }

  /// Stable small int for OS notification id (positive 31-bit).
  static int notificationIdFor(String reminderId) {
    return reminderId.hashCode & 0x7fffffff;
  }

  /// Create or replace the single reminder for an event.
  Future<Reminder> upsertForEvent({
    required String eventId,
    required int fireAt,
    required int offsetBeforeMin,
  }) async {
    final existing = await forEvent(eventId);
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;

    if (existing != null) {
      final notifId = existing.notificationId ?? notificationIdFor(existing.id);
      await (_db.update(_db.reminders)..where((t) => t.id.equals(existing.id)))
          .write(
        RemindersCompanion(
          fireAt: Value(fireAt),
          offsetBeforeMin: Value(offsetBeforeMin),
          notificationId: Value(notifId),
          status: const Value('scheduled'),
          updatedAt: Value(now),
        ),
      );
      return (await (_db.select(_db.reminders)
            ..where((t) => t.id.equals(existing.id)))
          .getSingle());
    }

    final id = _uuid.v4();
    final notifId = notificationIdFor(id);
    await _db.into(_db.reminders).insert(
          RemindersCompanion.insert(
            id: id,
            eventId: Value(eventId),
            fireAt: fireAt,
            offsetBeforeMin: Value(offsetBeforeMin),
            notificationId: Value(notifId),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return (await (_db.select(_db.reminders)..where((t) => t.id.equals(id)))
        .getSingle());
  }

  Future<void> cancelForEvent(String eventId) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    await (_db.update(_db.reminders)
          ..where(
            (t) => t.eventId.equals(eventId) & t.deleted.equals(false),
          ))
        .write(
      RemindersCompanion(
        status: const Value('cancelled'),
        deleted: const Value(true),
        updatedAt: Value(now),
      ),
    );
  }
}
