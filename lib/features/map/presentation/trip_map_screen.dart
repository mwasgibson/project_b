import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/db/app_database.dart';
import '../../../core/theme/domain_colors.dart';
import '../../../core/widgets/content_width.dart';
import '../../../core/widgets/empty_state.dart';
import '../../tracking/tracking_providers.dart';

/// Trip path between from/to visit centres (OSM tiles).
class TripMapScreen extends ConsumerWidget {
  const TripMapScreen({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_tripMapDataProvider(tripId));
    final domain = context.domainColors;

    return Scaffold(
      appBar: AppBar(title: const Text('Trip map')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load: $e')),
        data: (data) {
          if (data == null) {
            return const ContentWidth(
              child: EmptyState(
                icon: Icons.map_outlined,
                title: 'Trip not found',
                message: 'It may have been deleted.',
              ),
            );
          }
          final (from, to) = data;
          final a = LatLng(from.lat, from.lng);
          final b = LatLng(to.lat, to.lng);
          final center = LatLng(
            (a.latitude + b.latitude) / 2,
            (a.longitude + b.longitude) / 2,
          );

          return FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: 13,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.projectb.app',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [a, b],
                    color: domain.trip,
                    strokeWidth: 4,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: a,
                    width: 36,
                    height: 36,
                    child: Icon(Icons.trip_origin, color: domain.visit),
                  ),
                  Marker(
                    point: b,
                    width: 36,
                    height: 36,
                    child: Icon(Icons.place, color: domain.visit),
                  ),
                ],
              ),
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('OpenStreetMap contributors'),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

final _tripMapDataProvider =
    FutureProvider.family<(Visit, Visit)?, String>((ref, tripId) async {
  final db = ref.watch(databaseProvider);
  final trip = await (db.select(db.trips)..where((t) => t.id.equals(tripId)))
      .getSingleOrNull();
  if (trip == null) return null;
  final fromId = trip.fromVisitId;
  final toId = trip.toVisitId;
  if (fromId == null || toId == null) return null;
  final seg = ref.read(segmentationRepositoryProvider);
  final from = await seg.getVisit(fromId);
  final to = await seg.getVisit(toId);
  if (from == null || to == null) return null;
  return (from, to);
});
