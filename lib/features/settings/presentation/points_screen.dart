import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/content_width.dart';
import '../../../core/widgets/empty_state.dart';
import '../../tracking/tracking_providers.dart';

/// Recent raw points on this phone.
class PointsScreen extends ConsumerWidget {
  const PointsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final points = ref.watch(recentRawPointsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Saved points')),
      body: ContentWidth(
        child: points.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Could not load points: $e')),
          data: (rows) {
            if (rows.isEmpty) {
              return const EmptyState(
                icon: Icons.my_location_outlined,
                title: 'No points yet',
                message: 'Points appear when tracking is on and the phone '
                    'records a location sample.',
              );
            }
            final timeFmt = DateFormat.MMMd().add_Hm();
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: rows.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final p = rows[i];
                final t = DateTime.fromMillisecondsSinceEpoch(
                  p.recordedAt,
                  isUtc: true,
                ).toLocal();
                return ListTile(
                  dense: true,
                  title: Text(timeFmt.format(t)),
                  subtitle: Text(
                    '${p.lat.toStringAsFixed(5)}, ${p.lng.toStringAsFixed(5)}'
                    ' · ${p.mode}'
                    '${p.accuracyM != null ? ' · ±${p.accuracyM!.round()} m' : ''}'
                    '${p.processed ? '' : ' · pending'}',
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
