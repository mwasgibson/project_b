import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/db/app_database.dart';
import '../../../core/widgets/content_width.dart';
import '../../../core/widgets/empty_state.dart';
import '../../tracking/tracking_providers.dart';

/// S15 — saved / visited places.
class PlacesScreen extends ConsumerWidget {
  const PlacesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final placesAsync = ref.watch(placesByIdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Places')),
      body: ContentWidth(
        child: placesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Could not load places: $e')),
          data: (map) {
            final places = map.values.toList()
              ..sort((a, b) => (b.updatedAt).compareTo(a.updatedAt));
            if (places.isEmpty) {
              return const EmptyState(
                icon: Icons.place_outlined,
                title: 'No places yet',
                message:
                    'Places appear when visits are labelled or you rename a visit.',
              );
            }
            final timeFmt = DateFormat.yMMMd();
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: places.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final p = places[i];
                final name = (p.name?.trim().isNotEmpty == true)
                    ? p.name!.trim()
                    : 'Unnamed place';
                final source = p.nameSource == 'user' ? 'Named by you' : 'Auto';
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.place_outlined),
                    title: Text(name),
                    subtitle: Text(
                      [
                        source,
                        if (p.address != null && p.address!.trim().isNotEmpty)
                          p.address!.trim(),
                        '${p.lat.toStringAsFixed(4)}, ${p.lng.toStringAsFixed(4)}',
                        'Updated ${timeFmt.format(DateTime.fromMillisecondsSinceEpoch(p.updatedAt, isUtc: true).toLocal())}',
                      ].join(' · '),
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
