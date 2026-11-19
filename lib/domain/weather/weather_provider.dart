import 'weather_models.dart';

/// Behind this interface: Open-Meteo now, another API later (docs/02).
abstract interface class WeatherProvider {
  /// Fetch forecast for rounded coordinates. Implementations must not send
  /// full-precision location.
  Future<WeatherSnapshot> fetch({
    required double lat,
    required double lng,
  });
}

/// Round to ~1.1 km (2 decimal degrees) before any network call.
double roundCoordForWeather(double value) =>
    (value * 100).roundToDouble() / 100;
