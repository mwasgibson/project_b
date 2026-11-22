import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/db/app_database.dart';
import '../../../core/widgets/content_width.dart';
import '../../../core/widgets/empty_state.dart';
import '../../tracking/tracking_providers.dart';

enum _TrashTab { visits, places }

/// Soft-deleted visits and places.
class TrashScreen extends ConsumerStatefulWidget {
  const TrashScreen({super.key});

  @override
  ConsumerState<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends ConsumerState<TrashScreen> {
  final Set<String> _selected = {};
  bool _busy = false;
  _TrashTab _tab = _TrashTab.visits;

  void _toggle(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  void _selectAllIds(List<String> ids) {
    setState(() {
      if (_selected.length == ids.length && ids.isNotEmpty) {
        _selected.clear();
      } else {
        _selected
          ..clear()
          ..addAll(ids);
      }
    });
  }

  Future<void> _restoreSelected() async {
    if (_selected.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      if (_tab == _TrashTab.visits) {
        await ref
            .read(segmentationRepositoryProvider)
            .restoreVisits(_selected.toList());
        ref.invalidate(todaysTimelineProvider);
        ref.invalidate(deletedVisitsProvider);
        ref.invalidate(visitedPlacesProvider);
      } else {
        await ref
            .read(placesRepositoryProvider)
            .restorePlaces(_selected.toList());
        ref.invalidate(deletedPlacesProvider);
        ref.invalidate(placesByIdProvider);
        ref.invalidate(visitedPlacesProvider);
      }
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
    final kind = _tab == _TrashTab.visits ? 'visit' : 'place';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          count == 1
              ? 'Delete forever?'
              : 'Delete $count ${kind}s forever?',
        ),
        content: Text(
          _tab == _TrashTab.visits
              ? 'This cannot be undone. The selected visits are removed from this phone.'
              : 'This cannot be undone. Visits keep their times but lose this place name.',
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
      if (_tab == _TrashTab.visits) {
        await ref
            .read(segmentationRepositoryProvider)
            .permanentlyDeleteVisits(_selected.toList());
        ref.invalidate(deletedVisitsProvider);
      } else {
        await ref
            .read(placesRepositoryProvider)
            .permanentlyDeletePlaces(_selected.toList());
        ref.invalidate(deletedPlacesProvider);
        ref.invalidate(visitedPlacesProvider);
        ref.invalidate(placesByIdProvider);
      }
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

  String _visitTitle(Visit v, Map<String, Place> places) {
    final id = v.placeId;
    if (id != null) {
      final n = places[id]?.name?.trim();
      if (n != null && n.isNotEmpty) return n;
    }
    return 'Visit';
  }

  @override
  Widget build(BuildContext context) {
    final deletedVisits = ref.watch(deletedVisitsProvider);
    final deletedPlaces = ref.watch(deletedPlacesProvider);
    final places = ref.watch(placesByIdProvider).valueOrNull ?? {};
    final timeFmt = DateFormat.MMMd().add_Hm();
    final theme = Theme.of(context);

    final idsForTab = _tab == _TrashTab.visits
        ? (deletedVisits.valueOrNull ?? []).map((v) => v.id).toList()
        : (deletedPlaces.valueOrNull ?? []).map((p) => p.id).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trash'),
        actions: [
          if (idsForTab.isNotEmpty)
            TextButton(
              onPressed: _busy ? null : () => _selectAllIds(idsForTab),
              child: Text(
                _selected.length == idsForTab.length && idsForTab.isNotEmpty
                    ? 'Deselect all'
                    : 'Select all',
              ),
            ),
        ],
      ),
      body: ContentWidth(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: SegmentedButton<_TrashTab>(
                segments: const [
                  ButtonSegment(
                    value: _TrashTab.visits,
                    label: Text('Visits'),
                    icon: Icon(Icons.place_outlined),
                  ),
                  ButtonSegment(
                    value: _TrashTab.places,
                    label: Text('Places'),
                    icon: Icon(Icons.label_outline),
                  ),
                ],
                selected: {_tab},
                onSelectionChanged: (s) {
                  setState(() {
                    _tab = s.first;
                    _selected.clear();
                  });
                },
              ),
            ),
            Expanded(
              child: _tab == _TrashTab.visits
                  ? deletedVisits.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('Could not load: $e')),
                      data: (rows) => _listBody(
                        theme: theme,
                        emptyTitle: 'No visits in trash',
                        emptyMessage:
                            'Removed visits land here so you can restore them or delete them for good.',
                        itemCount: rows.length,
                        itemBuilder: (context, i) {
                          final v = rows[i];
                          final selected = _selected.contains(v.id);
                          final start =
                              DateTime.fromMillisecondsSinceEpoch(
                            v.startAt,
                            isUtc: true,
                          ).toLocal();
                          return _selectableCard(
                            theme: theme,
                            selected: selected,
                            title: _visitTitle(v, places),
                            subtitle: timeFmt.format(start),
                            onToggle: () => _toggle(v.id),
                          );
                        },
                        totalCount: rows.length,
                      ),
                    )
                  : deletedPlaces.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('Could not load: $e')),
                      data: (rows) => _listBody(
                        theme: theme,
                        emptyTitle: 'No places in trash',
                        emptyMessage:
                            'Removed place names land here. Visits stay; you can restore the name later.',
                        itemCount: rows.length,
                        itemBuilder: (context, i) {
                          final p = rows[i];
                          final selected = _selected.contains(p.id);
                          final name = (p.name?.trim().isNotEmpty == true)
                              ? p.name!.trim()
                              : 'Unnamed place';
                          return _selectableCard(
                            theme: theme,
                            selected: selected,
                            title: name,
                            subtitle: p.address?.trim().isNotEmpty == true
                                ? p.address!.trim()
                                : '${p.lat.toStringAsFixed(4)}, ${p.lng.toStringAsFixed(4)}',
                            onToggle: () => _toggle(p.id),
                          );
                        },
                        totalCount: rows.length,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _listBody({
    required ThemeData theme,
    required String emptyTitle,
    required String emptyMessage,
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
    required int totalCount,
  }) {
    if (itemCount == 0) {
      return EmptyState(
        icon: Icons.delete_outline,
        title: emptyTitle,
        message: emptyMessage,
      );
    }
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            itemCount: itemCount,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: itemBuilder,
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
                          ? '$totalCount in trash'
                          : '${_selected.length} selected',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed:
                        _selected.isEmpty || _busy ? null : _restoreSelected,
                    child: const Text('Restore'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed:
                        _selected.isEmpty || _busy ? null : _deleteSelected,
                    child: const Text('Delete'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _selectableCard({
    required ThemeData theme,
    required bool selected,
    required String title,
    required String subtitle,
    required VoidCallback onToggle,
  }) {
    return Card(
      color: selected
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.35)
          : null,
      child: ListTile(
        leading: Checkbox(
          value: selected,
          onChanged: _busy ? null : (_) => onToggle(),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        onTap: _busy ? null : onToggle,
      ),
    );
  }
}
