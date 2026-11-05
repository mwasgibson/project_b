import 'package:drift/drift.dart';

// Local schema, mirrors docs/05-backend-schema.md Part A.
// Times are UTC milliseconds since epoch; `utcOffsetMin` is the local offset at capture.
// IDs for synced records are UUID v7 generated on the device.

@TableIndex(name: 'raw_points_recorded_at', columns: {#recordedAt})
@TableIndex(name: 'raw_points_processed', columns: {#processed, #recordedAt})
class RawPoints extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get recordedAt => integer()();
  IntColumn get utcOffsetMin => integer()();
  RealColumn get lat => real()();
  RealColumn get lng => real()();
  RealColumn get accuracyM => real().nullable()();
  RealColumn get speedMps => real().nullable()();
  RealColumn get altitudeM => real().nullable()();
  TextColumn get activity => text().nullable()();
  IntColumn get batteryPct => integer().nullable()();

  /// high / balanced / saver at capture time.
  TextColumn get mode => text()();
  BoolColumn get processed => boolean().withDefault(const Constant(false))();
}

@TableIndex(name: 'places_lat_lng', columns: {#lat, #lng})
class Places extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().nullable()();

  /// `auto` or `user`.
  TextColumn get nameSource => text().withDefault(const Constant('auto'))();
  TextColumn get address => text().nullable()();
  RealColumn get lat => real()();
  RealColumn get lng => real()();
  IntColumn get radiusM => integer().withDefault(const Constant(100))();
  TextColumn get category => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@TableIndex(name: 'visits_start_at', columns: {#startAt})
@TableIndex(name: 'visits_place_id', columns: {#placeId})
class Visits extends Table {
  TextColumn get id => text()();
  TextColumn get placeId => text().nullable().references(Places, #id)();
  IntColumn get startAt => integer()();

  /// Null while the visit is still ongoing.
  IntColumn get endAt => integer().nullable()();
  IntColumn get utcOffsetMin => integer()();
  RealColumn get lat => real()();
  RealColumn get lng => real()();
  IntColumn get pointCount => integer().nullable()();

  /// pending / done / failed / disabled.
  TextColumn get labelState => text().withDefault(const Constant('pending'))();

  /// Protects user edits from being overwritten by re-segmentation.
  BoolColumn get userEdited => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@TableIndex(name: 'trips_start_at', columns: {#startAt})
class Trips extends Table {
  TextColumn get id => text()();
  TextColumn get fromVisitId => text().nullable().references(Visits, #id)();
  TextColumn get toVisitId => text().nullable().references(Visits, #id)();
  IntColumn get startAt => integer()();
  IntColumn get endAt => integer()();
  IntColumn get utcOffsetMin => integer()();
  RealColumn get distanceM => real().nullable()();

  /// walk / drive / unknown.
  TextColumn get modeGuess => text().nullable()();

  /// Compressed simplified polyline.
  BlobColumn get route => blob().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Derived, recomputed by the segmenter. Not synced.
class Gaps extends Table {
  TextColumn get id => text()();
  IntColumn get startAt => integer()();
  IntColumn get endAt => integer()();

  /// paused / permission / off / unknown.
  TextColumn get reason => text().withDefault(const Constant('unknown'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class CalendarEvents extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get notes => text().nullable()();
  IntColumn get startAt => integer()();
  IntColumn get endAt => integer()();
  BoolColumn get allDay => boolean().withDefault(const Constant(false))();
  IntColumn get utcOffsetMin => integer()();
  TextColumn get placeId => text().nullable().references(Places, #id)();
  TextColumn get locationText => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Reminders extends Table {
  TextColumn get id => text()();
  TextColumn get eventId => text().nullable().references(CalendarEvents, #id)();
  IntColumn get fireAt => integer()();
  IntColumn get offsetBeforeMin => integer().nullable()();

  /// OS handle used to cancel the scheduled notification.
  IntColumn get notificationId => integer().nullable()();

  /// scheduled / fired / cancelled.
  TextColumn get status => text().withDefault(const Constant('scheduled'))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class WeatherCache extends Table {
  /// Rounded lat,lng plus date.
  TextColumn get cacheKey => text()();
  IntColumn get fetchedAt => integer()();

  /// Provider JSON.
  TextColumn get payload => text()();

  @override
  Set<Column<Object>> get primaryKey => {cacheKey};
}

/// Simple key-value settings. Column names avoid SQL keywords on purpose.
class AppSettings extends Table {
  TextColumn get settingKey => text()();
  TextColumn get settingValue => text()();

  @override
  Set<Column<Object>> get primaryKey => {settingKey};
}

class SyncState extends Table {
  TextColumn get deviceId => text()();
  TextColumn get lastPullCursor => text().nullable()();
  IntColumn get lastPushAt => integer().nullable()();

  /// Small encrypted known value used to verify the passphrase.
  TextColumn get keyCheck => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {deviceId};
}

class SyncOutbox extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// place / visit / trip / event / reminder.
  TextColumn get recordKind => text()();
  TextColumn get recordId => text()();
  IntColumn get queuedAt => integer()();
}
