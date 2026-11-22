import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/db/app_database.dart';
import '../../../core/widgets/content_width.dart';
import '../../../core/widgets/empty_state.dart';
import '../../tracking/tracking_providers.dart';

/// Soft-deleted visits: select, restore, or permanently remove.
class TrashScreen extends ConsumerStatefulWidget {
  const TrashScreen({super.key});

  @override
  ConsumerState<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends ConsumerState<TrashScreen> {
  final Set<String> _selected = {};
  bool _busy = false;

  void _toggle(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  void _selectAll(List<Visit> rows) {
    setState(() {
      if (_selected.length == rows.length) {
        _selected.clear();
      } else {
        _selected
          ..clear()
          ..addAll(rows.map((v) => v.id));
      }
    });
  }

  Future<void> _restoreSelected() async {
    if (_selected.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(segmentationRepositoryProvider)
          .restoreVisits(_selected.toList());
      ref.invalidate(todaysTimelineProvider);
      ref.invalidate(deletedVisitsProvider);
      ref.invalidate(visitedPlacesProvider);
      if (mounted) {
        setState(() => _selected.clear());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Restored'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteSelected() async {
    if (_selected.isEmpty || _busy) return;
    final count = _selected.length;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(count == 1 ? 'Delete forever?' : 'Delete $count forever?'),
        content: const Text(
          'This cannot be undone. The selected visits are removed from this phone.',
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
    if (ok != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref
          .read(segmentationRepositoryProvider)
          .permanentlyDeleteVisits(_selected.toList());
      ref.invalidate(deletedVisitsProvider);
      if (mounted) {
        setState(() => _selected.clear());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deleted forever'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _titleFor(Visit v, Map places) {
    final id = v.placeId;
    if (id != null) {
      final n = places[id]?.name?.trim();
      if (n != null && n.isNotEmpty) return n as String;
    }
    return 'Visit';
  }

  @override
  Widget build(BuildContext context) {
    final deleted = ref.watch(deletedVisitsProvider);
    final places = ref.watch(placesByIdProvider).valueOrNull ?? {};
    final timeFmt = DateFormat.MMMd().add_Hm();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trash'),
        actions: [
          deleted.maybeWhen(
            data: (rows) {
              if (rows.isEmpty) return const SizedBox.shrink();
              final allSelected =
                  _selected.length == rows.length && rows.isNotEmpty;
              return TextButton(
                onPressed: _busy ? null : () => _selectAll(rows),
                child: Text(allSelected ? 'Deselect all' : 'Select all'),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
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
                    'Removed visits land here so you can restore them or delete them for good.',
              );
            }

            // Drop selection for ids that no longer exist.
            final ids = rows.map((v) => v.id).toSet();
            _selected.removeWhere((id) => !ids.contains(id));

            return Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    itemCount: rows.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final v = rows[i];
                      final selected = _selected.contains(v.id);
                      final start = DateTime.fromMillisecondsSinceEpoch(
                        v.startAt,
                        isUtc: true,
                      ).toLocal();
                      return Card(
                        color: selected
                            ? theme.colorScheme.primaryContainer
                                .withValues(alpha: 0.35)
                            : null,
                        child: ListTile(
                          leading: Checkbox(
                            value: selected,
                            onChanged: _busy
                                ? null
                                : (_) => _toggle(v.id),
                          ),
                          title: Text(_titleFor(v, places)),
                          subtitle: Text(timeFmt.format(start)),
                          onTap: _busy ? null : () => _toggle(v.id),
                        ),
                      );
                    },
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Material(
                    elevation: 2,
                    color: theme.colorScheme.surfaceContainerLowest,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _selected.isEmpty
                                  ? '${rows.length} in trash'
                                  : '${_selected.length} selected',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _selected.isEmpty || _busy
                                ? null
                                : _restoreSelected,
                            child: const Text('Restore'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: _selected.isEmpty || _busy
                                ? null
                                : _deleteSelected,
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
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
