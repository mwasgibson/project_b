import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/weather/weather_models.dart';
import '../../domain/weather/weather_provider.dart';
import 'app_database.dart';

class WeatherCacheRepository {
  WeatherCacheRepository(this._db);

  final AppDatabase _db;

  static String cacheKey(double latR, double lngR) =>
      '${latR.toStringAsFixed(2)},${lngR.toStringAsFixed(2)}';

  Future<WeatherSnapshot?> get(double lat, double lng) async {
    final latR = roundCoordForWeather(lat);
    final lngR = roundCoordForWeather(lng);
    final key = cacheKey(latR, lngR);
    final row = await (_db.select(_db.weatherCache)
          ..where((t) => t.cacheKey.equals(key)))
        .getSingleOrNull();
    if (row == null) return null;
    try {
      return _decode(row.payload, row.fetchedAt, latR, lngR);
    } catch (_) {
      return null;
    }
  }

  Future<void> put(WeatherSnapshot snap) async {
    final key = cacheKey(snap.latRounded, snap.lngRounded);
    await _db.into(_db.weatherCache).insertOnConflictUpdate(
          WeatherCacheCompanion.insert(
            cacheKey: key,
            fetchedAt: snap.fetchedAt.toUtc().millisecondsSinceEpoch,
            payload: _encode(snap),
          ),
        );
  }

  String _encode(WeatherSnapshot s) {
    return jsonEncode({
      'current': {
        'temperatureC': s.current.temperatureC,
        'weatherCode': s.current.weatherCode,
        'humidityPct': s.current.humidityPct,
        'windSpeedKmh': s.current.windSpeedKmh,
      },
      'daily': [
        for (final d in s.daily)
          {
            'date': d.date.toUtc().toIso8601String(),
            'weatherCode': d.weatherCode,
            'tempMaxC': d.tempMaxC,
            'tempMinC': d.tempMinC,
            'precipitationMm': d.precipitationMm,
          },
      ],
    });
  }

  WeatherSnapshot _decode(
    String payload,
    int fetchedAtMs,
    double latR,
    double lngR,
  ) {
    final map = jsonDecode(payload) as Map<String, dynamic>;
    final c = map['current'] as Map<String, dynamic>;
    final daily = (map['daily'] as List<dynamic>).map((raw) {
      final d = raw as Map<String, dynamic>;
      return DailyForecast(
        date: DateTime.parse(d['date'] as String),
        weatherCode: d['weatherCode'] as int,
        tempMaxC: (d['tempMaxC'] as num).toDouble(),
        tempMinC: (d['tempMinC'] as num).toDouble(),
        precipitationMm: (d['precipitationMm'] as num?)?.toDouble(),
      );
    }).toList();
    return WeatherSnapshot(
      latRounded: latR,
      lngRounded: lngR,
      fetchedAt: DateTime.fromMillisecondsSinceEpoch(fetchedAtMs, isUtc: true),
      current: CurrentWeather(
        temperatureC: (c['temperatureC'] as num).toDouble(),
        weatherCode: c['weatherCode'] as int,
        humidityPct: c['humidityPct'] as int?,
        windSpeedKmh: (c['windSpeedKmh'] as num?)?.toDouble(),
      ),
      daily: daily,
      fromCache: true,
    );
  }
}
