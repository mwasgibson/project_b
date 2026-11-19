import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/content_width.dart';
import '../../../core/widgets/empty_state.dart';
import '../../tracking/tracking_providers.dart';

/// Soft-deleted visits: restore or permanently remove.
class TrashScreen extends ConsumerWidget {
  const TrashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deleted = ref.watch(deletedVisitsProvider);
    final places = ref.watch(placesByIdProvider).valueOrNull ?? {};
    final timeFmt = DateFormat.MMMd().add_Hm();

    return Scaffold(
      appBar: AppBar(title: const Text('Deleted visits')),
      body: ContentWidth(
        child: deleted.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Could not load: $e')),
          data: (rows) {
            if (rows.isEmpty) {
              return const EmptyState(
                icon: Icons.delete_outline,
                title: 'Trash is empty',
                message:
                    'Deleted visits land here so you can restore them or remove them for good.',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: rows.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final v = rows[i];
                final name = () {
                  final id = v.placeId;
                  if (id != null) {
                    final n = places[id]?.name?.trim();
                    if (n != null && n.isNotEmpty) return n;
                  }
                  return 'Visit';
                }();
                final start = DateTime.fromMillisecondsSinceEpoch(
                  v.startAt,
                  isUtc: true,
                ).toLocal();
                return Card(
                  child: ListTile(
                    title: Text(name),
                    subtitle: Text(timeFmt.format(start)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () async {
                            await ref
                                .read(segmentationRepositoryProvider)
                                .restoreVisit(v.id);
                            ref.invalidate(todaysTimelineProvider);
                            ref.invalidate(deletedVisitsProvider);
                          },
                          child: const Text('Restore'),
                        ),
                        IconButton(
                          tooltip: 'Delete forever',
                          icon: const Icon(Icons.delete_forever_outlined),
                          onPressed: () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete forever?'),
                                content: const Text(
                                  'This cannot be undone. The visit is removed from this phone.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Delete forever'),
                                  ),
                                ],
                              ),
                            );
                            if (ok != true) return;
                            await ref
                                .read(segmentationRepositoryProvider)
                                .permanentlyDeleteVisit(v.id);
                            ref.invalidate(deletedVisitsProvider);
                          },
                        ),
                      ],
                    ),
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
