import 'package:flutter/material.dart' show ThemeMode;

import '../db/app_database.dart';
import 'setting_keys.dart';

class SettingsRepository {
  SettingsRepository(this._db);

  final AppDatabase _db;

  Stream<String?> watch(String key) {
    final query = _db.select(_db.appSettings)
      ..where((t) => t.settingKey.equals(key));
    return query.watchSingleOrNull().map((row) => row?.settingValue);
  }

  Future<String?> read(String key) async {
    final query = _db.select(_db.appSettings)
      ..where((t) => t.settingKey.equals(key));
    final row = await query.getSingleOrNull();
    return row?.settingValue;
  }

  Future<void> write(String key, String value) {
    return _db.into(_db.appSettings).insertOnConflictUpdate(
          AppSettingsCompanion.insert(settingKey: key, settingValue: value),
        );
  }

  Stream<ThemeMode> watchThemeMode() =>
      watch(SettingKeys.theme).map(_parseThemeMode);

  Future<void> setThemeMode(ThemeMode mode) =>
      write(SettingKeys.theme, mode.name);

  static ThemeMode _parseThemeMode(String? raw) => switch (raw) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
}
