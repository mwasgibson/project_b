import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/content_width.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../domain/weather/weather_models.dart';
import '../weather_providers.dart';

/// S12 — current conditions + multi-day forecast (Open-Meteo, rounded coords).
class WeatherScreen extends ConsumerWidget {
  const WeatherScreen({super.key});

  static IconData _icon(IconDataForWeather kind) => switch (kind) {
        IconDataForWeather.sun => Icons.wb_sunny_outlined,
        IconDataForWeather.cloudSun => Icons.wb_cloudy_outlined,
        IconDataForWeather.cloud => Icons.cloud_outlined,
        IconDataForWeather.fog => Icons.foggy,
        IconDataForWeather.rain => Icons.umbrella_outlined,
        IconDataForWeather.snow => Icons.ac_unit,
        IconDataForWeather.storm => Icons.thunderstorm_outlined,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(weatherSnapshotProvider);
    final theme = Theme.of(context);
    final dayFmt = DateFormat.E();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(weatherSnapshotProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ContentWidth(
        child: async.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(48),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, _) => EmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load weather',
            message:
                'Check your connection. If you tracked recently, a cached '
                'forecast may appear after retry.\n\n$e',
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(weatherSnapshotProvider),
          ),
          data: (snap) {
            if (snap == null) {
              return EmptyState(
                icon: Icons.my_location_outlined,
                title: 'Location needed',
                message:
                    'Weather uses a coarse location from tracking or the '
                    'phone’s last known position. Start tracking once, or '
                    'allow location, then refresh.',
                actionLabel: 'Retry',
                onAction: () => ref.invalidate(weatherSnapshotProvider),
              );
            }

            final c = snap.current;
            final kind = weatherIconKind(c.weatherCode);
            final updated = DateFormat.Hm().format(snap.fetchedAt.toLocal());

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (snap.fromCache || snap.isStale)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Material(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      child: ListTile(
                        dense: true,
                        leading: const Icon(Icons.history),
                        title: Text(
                          snap.fromCache && snap.isStale
                              ? 'Cached forecast · last updated $updated'
                              : snap.fromCache
                                  ? 'Showing cached forecast · $updated'
                                  : 'Last updated $updated',
                        ),
                      ),
                    ),
                  ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(
                          _icon(kind),
                          size: 56,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${c.temperatureC.round()}°',
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          weatherCodeLabel(c.weatherCode),
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (c.humidityPct != null) ...[
                              Icon(
                                Icons.water_drop_outlined,
                                size: 16,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${c.humidityPct}%',
                                style: theme.textTheme.bodyMedium,
                              ),
                              const SizedBox(width: 16),
                            ],
                            if (c.windSpeedKmh != null) ...[
                              Icon(
                                Icons.air,
                                size: 16,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${c.windSpeedKmh!.round()} km/h',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Near ${snap.latRounded.toStringAsFixed(2)}, '
                          '${snap.lngRounded.toStringAsFixed(2)} '
                          '(~1 km precision)',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Next days',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                for (final d in snap.daily)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        _icon(weatherIconKind(d.weatherCode)),
                        color: theme.colorScheme.primary,
                      ),
                      title: Text(dayFmt.format(d.date)),
                      subtitle: Text(
                        [
                          weatherCodeLabel(d.weatherCode),
                          if (d.precipitationMm != null &&
                              d.precipitationMm! > 0)
                            '${d.precipitationMm!.toStringAsFixed(1)} mm',
                        ].join(' · '),
                      ),
                      trailing: Text(
                        '${d.tempMaxC.round()}° / ${d.tempMinC.round()}°',
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  'Forecast from Open-Meteo. Location is rounded so the '
                  'request does not send precise coordinates.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
