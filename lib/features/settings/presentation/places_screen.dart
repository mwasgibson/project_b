import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../../core/widgets/content_width.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../domain/places/visited_place.dart';
import '../../tracking/tracking_providers.dart';

/// S15 — unique places visited, with counts.
class PlacesScreen extends ConsumerWidget {
  const PlacesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final placesAsync = ref.watch(visitedPlacesProvider);
    final theme = Theme.of(context);
    final dayFmt = DateFormat.MMMd().add_Hm();

    return Scaffold(
      appBar: AppBar(title: const Text('Places')),
      body: ContentWidth(
        child: placesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Could not load places: $e')),
          data: (places) {
            if (places.isEmpty) {
              return const EmptyState(
                icon: Icons.place_outlined,
                title: 'No places yet',
                message:
                    'When you stay somewhere while tracking, it shows up here.',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: places.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final p = places[i];
                final last = DateTime.fromMillisecondsSinceEpoch(
                  p.lastVisitAt,
                  isUtc: true,
                ).toLocal();
                final countLabel = p.visitCount == 1
                    ? '1 visit'
                    : '${p.visitCount} visits';
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.place_outlined,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    title: Text(p.name),
                    subtitle: Text(
                      [
                        countLabel,
                        'Last ${dayFmt.format(last)}',
                        if (p.address != null && p.address!.trim().isNotEmpty)
                          p.address!.trim(),
                      ].join(' · '),
                    ),
                    isThreeLine:
                        p.address != null && p.address!.trim().isNotEmpty,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(Routes.placeDetail(p.key)),
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

/// Detail: every visit at this place.
class PlaceDetailScreen extends ConsumerWidget {
  const PlaceDetailScreen({super.key, required this.placeKey});

  final String placeKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final placesAsync = ref.watch(visitedPlacesProvider);
    final theme = Theme.of(context);
    final dayFmt = DateFormat.yMMMEd().add_Hm();
    final timeFmt = DateFormat.Hm();

    return Scaffold(
      appBar: AppBar(title: const Text('Place')),
      body: ContentWidth(
        child: placesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Could not load: $e')),
          data: (list) {
            VisitedPlace? place;
            for (final p in list) {
              if (p.key == placeKey) {
                place = p;
                break;
              }
            }
            if (place == null) {
              return const EmptyState(
                icon: Icons.place_outlined,
                title: 'Place not found',
                message: 'It may have been merged or removed.',
              );
            }

            final p = place;
            final countLabel =
                p.visitCount == 1 ? '1 visit' : '${p.visitCount} visits';
            final canTrash = p.placeId != null;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  p.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (p.address != null && p.address!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    p.address!.trim(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  countLabel,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                if (canTrash) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Remove this place?'),
                          content: const Text(
                            'The name moves to Trash. Visits stay on the timeline '
                            'without this label until you restore it.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Remove'),
                            ),
                          ],
                        ),
                      );
                      if (ok != true || !context.mounted) return;
                      await ref
                          .read(placesRepositoryProvider)
                          .softDelete(p.placeId!);
                      ref.invalidate(visitedPlacesProvider);
                      ref.invalidate(placesByIdProvider);
                      ref.invalidate(deletedPlacesProvider);
                      if (context.mounted) context.pop();
                    },
                    icon: Icon(
                      Icons.delete_outline,
                      color: theme.colorScheme.error,
                    ),
                    label: Text(
                      'Remove place',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Text('Visits', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                for (final v in p.visits)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.schedule_outlined),
                      title: Text(
                        dayFmt.format(
                          DateTime.fromMillisecondsSinceEpoch(
                            v.startAt,
                            isUtc: true,
                          ).toLocal(),
                        ),
                      ),
                      subtitle: Text(
                        () {
                          final start = DateTime.fromMillisecondsSinceEpoch(
                            v.startAt,
                            isUtc: true,
                          ).toLocal();
                          final end = v.endAt == null
                              ? null
                              : DateTime.fromMillisecondsSinceEpoch(
                                  v.endAt!,
                                  isUtc: true,
                                ).toLocal();
                          final span = end == null
                              ? '${timeFmt.format(start)} – ongoing'
                              : '${timeFmt.format(start)} – ${timeFmt.format(end)}';
                          final d = end == null
                              ? null
                              : Duration(
                                  milliseconds: v.endAt! - v.startAt,
                                );
                          if (d == null) return span;
                          final dur = d.inHours >= 1
                              ? '${d.inHours} h ${d.inMinutes.remainder(60)} min'
                              : '${d.inMinutes} min';
                          return '$span · $dur';
                        }(),
                      ),
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
