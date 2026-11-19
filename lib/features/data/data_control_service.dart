import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/db/app_database.dart';
import '../../core/settings/setting_keys.dart';
import '../../core/settings/settings_repository.dart';

/// F8 — export, erase, retention (docs/01, docs/03 Flow H).
class DataControlService {
  DataControlService({
    required AppDatabase db,
    required SettingsRepository settings,
  })  : _db = db,
        _settings = settings;

  final AppDatabase _db;
  final SettingsRepository _settings;

  Future<int> rawPointCount() async {
    final c = _db.rawPoints.id.count();
    final row = await (_db.selectOnly(_db.rawPoints)..addColumns([c])).getSingle();
    return row.read(c) ?? 0;
  }

  Future<int> visitCount() async {
    final c = _db.visits.id.count();
    final q = _db.selectOnly(_db.visits)
      ..addColumns([c])
      ..where(_db.visits.deleted.equals(false));
    final row = await q.getSingle();
    return row.read(c) ?? 0;
  }

  Future<int> tripCount() async {
    final c = _db.trips.id.count();
    final q = _db.selectOnly(_db.trips)
      ..addColumns([c])
      ..where(_db.trips.deleted.equals(false));
    final row = await q.getSingle();
    return row.read(c) ?? 0;
  }

  Future<int> eventCount() async {
    final c = _db.calendarEvents.id.count();
    final q = _db.selectOnly(_db.calendarEvents)
      ..addColumns([c])
      ..where(_db.calendarEvents.deleted.equals(false));
    final row = await q.getSingle();
    return row.read(c) ?? 0;
  }

  /// Default 30 days (docs/01 F8).
  Future<int> retentionDays() async {
    final raw = await _settings.read(SettingKeys.rawRetentionDays);
    return int.tryParse(raw ?? '') ?? 30;
  }

  Future<void> setRetentionDays(int days) async {
    final clamped = days.clamp(1, 365);
    await _settings.write(SettingKeys.rawRetentionDays, '$clamped');
  }

  /// Deletes raw points older than the retention window. Visits/trips stay.
  Future<int> purgeExpiredRawPoints() async {
    final days = await retentionDays();
    final cutoff = DateTime.now()
        .toUtc()
        .subtract(Duration(days: days))
        .millisecondsSinceEpoch;
    return (_db.delete(_db.rawPoints)
          ..where((t) => t.recordedAt.isSmallerThanValue(cutoff)))
        .go();
  }

  /// Share a full local snapshot as JSON (no cloud keys).
  Future<void> exportJson() async {
    final payload = await _buildJsonExport();
    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().toUtc().toIso8601String().replaceAll(':', '-');
    final file = File('${dir.path}/project_b_export_$stamp.json');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      subject: 'Project B data export',
      text: 'Local Project B export ($stamp)',
    );
  }

  /// GPX 1.1 with visit waypoints and trip track segments (endpoints).
  Future<void> exportGpx() async {
    final gpx = await _buildGpx();
    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().toUtc().toIso8601String().replaceAll(':', '-');
    final file = File('${dir.path}/project_b_routes_$stamp.gpx');
    await file.writeAsString(gpx);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/gpx+xml')],
      subject: 'Project B GPX export',
      text: 'Visits and trips from Project B ($stamp)',
    );
  }

  /// Wipes local location history, places, calendar, weather cache.
  /// Keeps theme / onboarding / tracking preference settings.
  Future<void> deleteAllLocalData() async {
    await _db.transaction(() async {
      await _db.delete(_db.reminders).go();
      await _db.delete(_db.calendarEvents).go();
      await _db.delete(_db.trips).go();
      await _db.delete(_db.visits).go();
      await _db.delete(_db.gaps).go();
      await _db.delete(_db.rawPoints).go();
      await _db.delete(_db.places).go();
      await _db.delete(_db.weatherCache).go();
      await _db.delete(_db.syncOutbox).go();
      // Leave app_settings and sync_state (passphrase material) alone.
    });
  }

  Future<Map<String, Object?>> _buildJsonExport() async {
    final places = await (_db.select(_db.places)
          ..where((t) => t.deleted.equals(false)))
        .get();
    final visits = await (_db.select(_db.visits)
          ..where((t) => t.deleted.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.startAt)]))
        .get();
    final trips = await (_db.select(_db.trips)
          ..where((t) => t.deleted.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.startAt)]))
        .get();
    final events = await (_db.select(_db.calendarEvents)
          ..where((t) => t.deleted.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.startAt)]))
        .get();
    final reminders = await (_db.select(_db.reminders)
          ..where((t) => t.deleted.equals(false)))
        .get();
    final points = await (_db.select(_db.rawPoints)
          ..orderBy([(t) => OrderingTerm.asc(t.recordedAt)]))
        .get();
    final settings = await _db.select(_db.appSettings).get();

    return {
      'format': 'project_b_export',
      'version': 1,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'places': [
        for (final p in places)
          {
            'id': p.id,
            'name': p.name,
            'nameSource': p.nameSource,
            'address': p.address,
            'lat': p.lat,
            'lng': p.lng,
            'radiusM': p.radiusM,
            'category': p.category,
            'createdAt': p.createdAt,
            'updatedAt': p.updatedAt,
          },
      ],
      'visits': [
        for (final v in visits)
          {
            'id': v.id,
            'placeId': v.placeId,
            'startAt': v.startAt,
            'endAt': v.endAt,
            'utcOffsetMin': v.utcOffsetMin,
            'lat': v.lat,
            'lng': v.lng,
            'pointCount': v.pointCount,
            'labelState': v.labelState,
            'userEdited': v.userEdited,
          },
      ],
      'trips': [
        for (final t in trips)
          {
            'id': t.id,
            'fromVisitId': t.fromVisitId,
            'toVisitId': t.toVisitId,
            'startAt': t.startAt,
            'endAt': t.endAt,
            'utcOffsetMin': t.utcOffsetMin,
            'distanceM': t.distanceM,
            'modeGuess': t.modeGuess,
          },
      ],
      'events': [
        for (final e in events)
          {
            'id': e.id,
            'title': e.title,
            'notes': e.notes,
            'startAt': e.startAt,
            'endAt': e.endAt,
            'allDay': e.allDay,
            'utcOffsetMin': e.utcOffsetMin,
            'locationText': e.locationText,
          },
      ],
      'reminders': [
        for (final r in reminders)
          {
            'id': r.id,
            'eventId': r.eventId,
            'fireAt': r.fireAt,
            'offsetBeforeMin': r.offsetBeforeMin,
            'status': r.status,
          },
      ],
      'rawPoints': [
        for (final p in points)
          {
            'id': p.id,
            'recordedAt': p.recordedAt,
            'utcOffsetMin': p.utcOffsetMin,
            'lat': p.lat,
            'lng': p.lng,
            'accuracyM': p.accuracyM,
            'speedMps': p.speedMps,
            'altitudeM': p.altitudeM,
            'activity': p.activity,
            'batteryPct': p.batteryPct,
            'mode': p.mode,
            'processed': p.processed,
          },
      ],
      'settings': {
        for (final s in settings)
          if (s.settingKey != SettingKeys.syncEnabled)
            s.settingKey: s.settingValue,
      },
    };
  }

  Future<String> _buildGpx() async {
    final visits = await (_db.select(_db.visits)
          ..where((t) => t.deleted.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.startAt)]))
        .get();
    final trips = await (_db.select(_db.trips)
          ..where((t) => t.deleted.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.startAt)]))
        .get();
    final places = {
      for (final p in await (_db.select(_db.places)
            ..where((t) => t.deleted.equals(false)))
          .get())
        p.id: p,
    };

    final buf = StringBuffer()
      ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
      ..writeln(
        '<gpx version="1.1" creator="Project B" '
        'xmlns="http://www.topografix.com/GPX/1/1">',
      )
      ..writeln('  <metadata>')
      ..writeln('    <name>Project B export</name>')
      ..writeln('    <time>${DateTime.now().toUtc().toIso8601String()}</time>')
      ..writeln('  </metadata>');

    for (final v in visits) {
      final name = (v.placeId != null ? places[v.placeId!]?.name : null) ??
          'Visit';
      final time = DateTime.fromMillisecondsSinceEpoch(v.startAt, isUtc: true)
          .toIso8601String();
      buf
        ..writeln('  <wpt lat="${v.lat}" lon="${v.lng}">')
        ..writeln('    <time>$time</time>')
        ..writeln('    <name>${_xmlEscape(name)}</name>')
        ..writeln('    <type>visit</type>')
        ..writeln('  </wpt>');
    }

    // Trip as a two-point track between linked visit centres when available.
    final visitById = {for (final v in visits) v.id: v};
    for (final t in trips) {
      final from = t.fromVisitId == null ? null : visitById[t.fromVisitId!];
      final to = t.toVisitId == null ? null : visitById[t.toVisitId!];
      if (from == null || to == null) continue;
      final t0 = DateTime.fromMillisecondsSinceEpoch(t.startAt, isUtc: true)
          .toIso8601String();
      final t1 = DateTime.fromMillisecondsSinceEpoch(t.endAt, isUtc: true)
          .toIso8601String();
      buf
        ..writeln('  <trk>')
        ..writeln('    <name>Trip</name>')
        ..writeln('    <type>trip</type>')
        ..writeln('    <trkseg>')
        ..writeln('      <trkpt lat="${from.lat}" lon="${from.lng}">')
        ..writeln('        <time>$t0</time>')
        ..writeln('      </trkpt>')
        ..writeln('      <trkpt lat="${to.lat}" lon="${to.lng}">')
        ..writeln('        <time>$t1</time>')
        ..writeln('      </trkpt>')
        ..writeln('    </trkseg>')
        ..writeln('  </trk>');
    }

    buf.writeln('</gpx>');
    return buf.toString();
  }

  static String _xmlEscape(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}
