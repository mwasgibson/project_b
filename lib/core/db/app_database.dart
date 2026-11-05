import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    RawPoints,
    Places,
    Visits,
    Trips,
    Gaps,
    CalendarEvents,
    Reminders,
    WeatherCache,
    AppSettings,
    SyncState,
    SyncOutbox,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Pass an in-memory executor in tests.
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'project_b'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        // Future schema changes go in onUpgrade, with a test per step.
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
