import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/db/app_database.dart';
import '../../tracking/tracking_providers.dart';

/// S7 — visit detail: rename place, retry label, delete.
class VisitDetailSheet extends ConsumerWidget {
  const VisitDetailSheet({
    super.key,
    required this.visit,
    this.place,
  });

  final Visit visit;
  final Place? place;

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

  static Future<void> show(
    BuildContext context,
    Visit visit, {
    Place? place,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => VisitDetailSheet(visit: visit, place: place),
    );
  }

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => _RenamePlaceDialog(
        initial: place?.name?.trim() ?? '',
      ),
    );
    if (name == null || name.isEmpty || !context.mounted) return;

    final placeRow =
        await ref.read(placesRepositoryProvider).ensureUserNamedPlace(
              name: name,
              lat: visit.lat,
              lng: visit.lng,
              existingPlaceId: place?.id ?? visit.placeId,
            );
    await ref.read(segmentationRepositoryProvider).attachPlace(
          visitId: visit.id,
          placeId: placeRow.id,
        );
    ref.invalidate(todaysTimelineProvider);
    ref.invalidate(placesByIdProvider);
    if (context.mounted) Navigator.pop(context);
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

    final title = place?.name?.trim().isNotEmpty == true
        ? place!.name!.trim()
        : switch (visit.labelState) {
            'pending' => 'Labelling…',
            'disabled' => 'Unlabelled place',
            _ => 'Unknown place',
          };

    final isUserNamed = place?.nameSource == 'user';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isUserNamed) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Named by you',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Rename',
                  onPressed: () => _rename(context, ref),
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
            if (place?.address != null &&
                place!.address!.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                place!.address!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ] else if (visit.labelState == 'pending') ...[
              const SizedBox(height: 4),
              Text(
                'Looking up a name via the phone’s place service…',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ] else if (visit.labelState == 'disabled') ...[
              const SizedBox(height: 4),
              Text(
                'Auto-labelling is off. Turn it on in Tracking settings.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
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
            FilledButton.tonalIcon(
              onPressed: () => _rename(context, ref),
              icon: const Icon(Icons.edit_outlined),
              label: Text(place == null ? 'Name this place' : 'Rename place'),
            ),
            const SizedBox(height: 8),
            if (visit.labelState == 'pending' ||
                visit.labelState == 'failed') ...[
              OutlinedButton.icon(
                onPressed: () async {
                  await ref
                      .read(placeLabelServiceProvider)
                      .relabelVisit(visit.id);
                  ref.invalidate(todaysTimelineProvider);
                  ref.invalidate(placesByIdProvider);
                  if (context.mounted) Navigator.pop(context);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry auto-label'),
              ),
              const SizedBox(height: 8),
            ],
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
              icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
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

/// Owns the [TextEditingController] for the full dialog route lifetime.
class _RenamePlaceDialog extends StatefulWidget {
  const _RenamePlaceDialog({required this.initial});

  final String initial;

  @override
  State<_RenamePlaceDialog> createState() => _RenamePlaceDialogState();
}

class _RenamePlaceDialogState extends State<_RenamePlaceDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() => Navigator.pop(context, _controller.text.trim());

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rename place'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          hintText: 'e.g. Home, Java House',
          labelText: 'Name',
        ),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
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
