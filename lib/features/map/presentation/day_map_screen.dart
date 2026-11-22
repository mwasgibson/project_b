import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/db/app_database.dart';
import '../../../core/theme/domain_colors.dart';
import '../../../core/widgets/content_width.dart';
import '../../../core/widgets/empty_state.dart';
import '../../tracking/tracking_providers.dart';

/// Day map: visit pins for a local calendar day (OSM tiles).
class DayMapScreen extends ConsumerWidget {
  const DayMapScreen({super.key, required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visitsAsync = ref.watch(
      segmentationRepositoryProvider.select(
        (repo) => repo.watchVisitsForDay(day),
      ),
    );
    // Riverpod StreamProvider wrapper:
    final stream = ref.watch(_visitsForDayProvider(day));
    final places = ref.watch(placesByIdProvider).valueOrNull ?? {};
    final domain = context.domainColors;
    final label = DateFormat.MMMEd().format(day);

    return Scaffold(
      appBar: AppBar(title: Text('Map · $label')),
      body: stream.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load: $e')),
        data: (visits) {
          if (visits.isEmpty) {
            return const ContentWidth(
              child: EmptyState(
                icon: Icons.map_outlined,
                title: 'Nothing to map',
                message: 'No visits on this day yet.',
              ),
            );
          }

          final points = [
            for (final v in visits) LatLng(v.lat, v.lng),
          ];
          final center = _center(points);

          return FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: points.length == 1 ? 15 : 13,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.projectb.app',
              ),
              MarkerLayer(
                markers: [
                  for (final v in visits)
                    Marker(
                      point: LatLng(v.lat, v.lng),
                      width: 40,
                      height: 40,
                      child: Tooltip(
                        message: _name(v, places),
                        child: Icon(
                          Icons.place,
                          color: domain.visit,
                          size: 36,
                        ),
                      ),
                    ),
                ],
              ),
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    'OpenStreetMap contributors',
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  static String _name(Visit v, Map<String, Place> places) {
    final id = v.placeId;
    if (id != null) {
      final n = places[id]?.name?.trim();
      if (n != null && n.isNotEmpty) return n;
    }
    return 'Visit';
  }

  static LatLng _center(List<LatLng> pts) {
    if (pts.isEmpty) return const LatLng(0, 0);
    var lat = 0.0;
    var lng = 0.0;
    for (final p in pts) {
      lat += p.latitude;
      lng += p.longitude;
    }
    return LatLng(lat / pts.length, lng / pts.length);
  }
}

final _visitsForDayProvider =
    StreamProvider.family<List<Visit>, DateTime>((ref, day) {
  return ref.watch(segmentationRepositoryProvider).watchVisitsForDay(day);
});
