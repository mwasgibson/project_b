import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/db/app_database.dart';
import '../../tracking/tracking_providers.dart';

/// S7 — visit detail (docs/03). Rename lands with Phase 5 labelling.
class VisitDetailSheet extends ConsumerWidget {
  const VisitDetailSheet({super.key, required this.visit});

  final Visit visit;

  static String _duration(int startMs, int? endMs) {
    if (endMs == null) return 'Ongoing';
    final d = Duration(milliseconds: endMs - startMs);
    if (d.inHours >= 1) {
      final m = d.inMinutes.remainder(60);
      return m == 0 ? '${d.inHours} h' : '${d.inHours} h $m min';
    }
    if (d.inMinutes < 1) return '${d.inSeconds} s';
    return '${d.inMinutes} min';
  }

  static Future<void> show(BuildContext context, Visit visit) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => VisitDetailSheet(visit: visit),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final timeFmt = DateFormat.Hm();
    final start = DateTime.fromMillisecondsSinceEpoch(
      visit.startAt,
      isUtc: true,
    ).toLocal();
    final end = visit.endAt == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(visit.endAt!, isUtc: true)
            .toLocal();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Unknown place',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Names arrive when place labelling is on (next phase).',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            _Row(
              icon: Icons.schedule_outlined,
              label: 'Time',
              value:
                  '${timeFmt.format(start)} – ${end == null ? 'now' : timeFmt.format(end)}',
            ),
            _Row(
              icon: Icons.timelapse_outlined,
              label: 'Duration',
              value: _duration(visit.startAt, visit.endAt),
            ),
            _Row(
              icon: Icons.my_location_outlined,
              label: 'Coordinates',
              value:
                  '${visit.lat.toStringAsFixed(5)}, ${visit.lng.toStringAsFixed(5)}',
            ),
            _Row(
              icon: Icons.bubble_chart_outlined,
              label: 'Points',
              value: '${visit.pointCount ?? 0}',
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete this visit?'),
                    content: const Text(
                      'The visit is removed from your timeline. '
                      'Raw points stay on this phone until retention clears them.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (ok != true || !context.mounted) return;
                await ref
                    .read(segmentationRepositoryProvider)
                    .softDeleteVisit(visit.id);
                ref.invalidate(todaysTimelineProvider);
                if (context.mounted) Navigator.pop(context);
              },
              icon: Icon(Icons.delete_outline,
                  color: theme.colorScheme.error),
              label: Text(
                'Delete visit',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(value, style: theme.textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
