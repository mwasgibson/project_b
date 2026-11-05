import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:project_b/core/db/app_database.dart';
import 'package:project_b/core/settings/settings_repository.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('schema', () {
    test('place gets documented defaults', () async {
      await db.into(db.places).insert(
            PlacesCompanion.insert(
              id: 'p1',
              lat: -1.2921,
              lng: 36.8219,
              createdAt: 1,
              updatedAt: 1,
            ),
          );
      final place = await (db.select(db.places)
            ..where((t) => t.id.equals('p1')))
          .getSingle();
      expect(place.radiusM, 100);
      expect(place.nameSource, 'auto');
      expect(place.deleted, isFalse);
    });

    test('visit may reference an existing place', () async {
      await db.into(db.places).insert(
            PlacesCompanion.insert(
              id: 'p1',
              lat: 0,
              lng: 0,
              createdAt: 1,
              updatedAt: 1,
            ),
          );
      await db.into(db.visits).insert(
            VisitsCompanion.insert(
              id: 'v1',
              startAt: 1000,
              utcOffsetMin: 180,
              lat: 0,
              lng: 0,
              createdAt: 1,
              updatedAt: 1,
              placeId: const Value('p1'),
            ),
          );
      final visit = await (db.select(db.visits)
            ..where((t) => t.id.equals('v1')))
          .getSingle();
      expect(visit.placeId, 'p1');
      expect(visit.labelState, 'pending');
      expect(visit.userEdited, isFalse);
    });

    test('foreign keys are enforced', () async {
      final insert = db.into(db.visits).insert(
            VisitsCompanion.insert(
              id: 'v2',
              startAt: 1,
              utcOffsetMin: 0,
              lat: 0,
              lng: 0,
              createdAt: 1,
              updatedAt: 1,
              placeId: const Value('does-not-exist'),
            ),
          );
      await expectLater(insert, throwsA(anything));
    });
  });

  group('SettingsRepository', () {
    test('defaults to system theme when nothing is stored', () async {
      final repo = SettingsRepository(db);
      expect(await repo.watchThemeMode().first, ThemeMode.system);
    });

    test('stores and returns the chosen theme', () async {
      final repo = SettingsRepository(db);
      await repo.setThemeMode(ThemeMode.dark);
      expect(await repo.watchThemeMode().first, ThemeMode.dark);
      await repo.setThemeMode(ThemeMode.light);
      expect(await repo.watchThemeMode().first, ThemeMode.light);
    });
  });
}
