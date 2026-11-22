/// Domain models for weather (docs/02 F7). No network types here.
library;

class WeatherSnapshot {
  const WeatherSnapshot({
    required this.latRounded,
    required this.lngRounded,
    required this.fetchedAt,
    required this.current,
    required this.daily,
    this.fromCache = false,
  });

  final double latRounded;
  final double lngRounded;
  final DateTime fetchedAt;
  final CurrentWeather current;
  final List<DailyForecast> daily;
  final bool fromCache;

  bool get isStale {
    final age = DateTime.now().difference(fetchedAt);
    return age > const Duration(hours: 3);
  }
}

class CurrentWeather {
  const CurrentWeather({
    required this.temperatureC,
    required this.weatherCode,
    this.humidityPct,
    this.windSpeedKmh,
  });

  final double temperatureC;
  final int weatherCode;
  final int? humidityPct;
  final double? windSpeedKmh;
}

class DailyForecast {
  const DailyForecast({
    required this.date,
    required this.weatherCode,
    required this.tempMaxC,
    required this.tempMinC,
    this.precipitationMm,
  });

  final DateTime date;
  final int weatherCode;
  final double tempMaxC;
  final double tempMinC;
  final double? precipitationMm;
}

/// WMO weather interpretation codes used by Open-Meteo.
String weatherCodeLabel(int code) {
  if (code == 0) return 'Clear';
  if (code <= 3) return 'Partly cloudy';
  if (code <= 48) return 'Fog';
  if (code <= 57) return 'Drizzle';
  if (code <= 67) return 'Rain';
  if (code <= 77) return 'Snow';
  if (code <= 82) return 'Showers';
  if (code <= 86) return 'Snow showers';
  if (code <= 99) return 'Thunderstorm';
  return 'Unknown';
}

IconDataForWeather weatherIconKind(int code) {
  if (code == 0) return IconDataForWeather.sun;
  if (code <= 3) return IconDataForWeather.cloudSun;
  if (code <= 48) return IconDataForWeather.fog;
  if (code <= 67 || (code >= 80 && code <= 82)) return IconDataForWeather.rain;
  if (code <= 77 || (code >= 85 && code <= 86)) return IconDataForWeather.snow;
  if (code >= 95) return IconDataForWeather.storm;
  return IconDataForWeather.cloud;
}

enum IconDataForWeather { sun, cloudSun, cloud, fog, rain, snow, storm }
