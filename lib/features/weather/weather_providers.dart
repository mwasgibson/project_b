import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/db/weather_cache_repository.dart';
import '../../core/providers.dart';
import '../../domain/weather/weather_models.dart';
import '../../domain/weather/weather_provider.dart';
import '../tracking/tracking_providers.dart';
import 'data/open_meteo_weather_provider.dart';

final weatherCacheRepositoryProvider = Provider<WeatherCacheRepository>(
  (ref) => WeatherCacheRepository(ref.watch(databaseProvider)),
);

final weatherProviderImplProvider = Provider<WeatherProvider>(
  (ref) => OpenMeteoWeatherProvider(),
);

/// Best-effort location for weather: last raw point, else device last-known.
final weatherLocationProvider = FutureProvider<(double, double)?>((ref) async {
  final points = ref.watch(rawPointsRepositoryProvider);
  final last = await points.lastSample();
  if (last != null) return (last.lat, last.lng);

  try {
    final pos = await Geolocator.getLastKnownPosition();
    if (pos != null) return (pos.latitude, pos.longitude);
  } catch (_) {}
  try {
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
        timeLimit: Duration(seconds: 8),
      ),
    );
    return (pos.latitude, pos.longitude);
  } catch (_) {
    return null;
  }
});

final weatherSnapshotProvider =
    FutureProvider.autoDispose<WeatherSnapshot?>((ref) async {
  final loc = await ref.watch(weatherLocationProvider.future);
  if (loc == null) return null;

  final (lat, lng) = loc;
  final cache = ref.watch(weatherCacheRepositoryProvider);
  final cached = await cache.get(lat, lng);

  try {
    final fresh = await ref.watch(weatherProviderImplProvider).fetch(
          lat: lat,
          lng: lng,
        );
    await cache.put(fresh);
    return fresh;
  } catch (_) {
    if (cached != null) return cached;
    rethrow;
  }
});

/// Daily row for a local calendar day, if present in the snapshot.
final weatherForDayProvider =
    Provider.family<DailyForecast?, DateTime>((ref, day) {
  final snap = ref.watch(weatherSnapshotProvider).valueOrNull;
  if (snap == null) return null;
  for (final d in snap.daily) {
    if (d.date.year == day.year &&
        d.date.month == day.month &&
        d.date.day == day.day) {
      return d;
    }
  }
  return null;
});
