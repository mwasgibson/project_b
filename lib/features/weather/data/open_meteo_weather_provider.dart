import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../domain/weather/weather_models.dart';
import '../../../domain/weather/weather_provider.dart';

/// Free Open-Meteo forecast API — no key. Coords must already be rounded.
class OpenMeteoWeatherProvider implements WeatherProvider {
  OpenMeteoWeatherProvider({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<WeatherSnapshot> fetch({
    required double lat,
    required double lng,
  }) async {
    final latR = roundCoordForWeather(lat);
    final lngR = roundCoordForWeather(lng);

    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': latR.toStringAsFixed(2),
      'longitude': lngR.toStringAsFixed(2),
      'current':
          'temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m',
      'daily':
          'weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum',
      'timezone': 'auto',
      'forecast_days': '7',
    });

    final res = await _client.get(uri).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw StateError('Weather request failed (${res.statusCode})');
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final current = json['current'] as Map<String, dynamic>;
    final daily = json['daily'] as Map<String, dynamic>;
    final times = (daily['time'] as List<dynamic>).cast<String>();
    final codes = (daily['weather_code'] as List<dynamic>).cast<num>();
    final maxes = (daily['temperature_2m_max'] as List<dynamic>).cast<num>();
    final mins = (daily['temperature_2m_min'] as List<dynamic>).cast<num>();
    final precip = (daily['precipitation_sum'] as List<dynamic>?)?.cast<num>();

    final days = <DailyForecast>[
      for (var i = 0; i < times.length; i++)
        DailyForecast(
          date: DateTime.parse(times[i]),
          weatherCode: codes[i].toInt(),
          tempMaxC: maxes[i].toDouble(),
          tempMinC: mins[i].toDouble(),
          precipitationMm: precip == null ? null : precip[i].toDouble(),
        ),
    ];

    return WeatherSnapshot(
      latRounded: latR,
      lngRounded: lngR,
      fetchedAt: DateTime.now().toUtc(),
      current: CurrentWeather(
        temperatureC: (current['temperature_2m'] as num).toDouble(),
        weatherCode: (current['weather_code'] as num).toInt(),
        humidityPct: (current['relative_humidity_2m'] as num?)?.toInt(),
        windSpeedKmh: (current['wind_speed_10m'] as num?)?.toDouble(),
      ),
      daily: days,
    );
  }
}
