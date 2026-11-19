import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/content_width.dart';
import '../../data/data_control_providers.dart';
import '../../tracking/tracking_providers.dart';

/// S17 — export, retention summary, delete all (docs/03 Flow H).
class DataScreen extends ConsumerStatefulWidget {
  const DataScreen({super.key});

  @override
  ConsumerState<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends ConsumerState<DataScreen> {
  bool _busy = false;
  _Counts? _counts;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final svc = ref.read(dataControlServiceProvider);
    await svc.purgeExpiredRawPoints();
    final counts = _Counts(
      visits: await svc.visitCount(),
      trips: await svc.tripCount(),
      events: await svc.eventCount(),
      retentionDays: await svc.retentionDays(),
    );
    if (mounted) setState(() => _counts = counts);
  }

  Future<void> _run(Future<void> Function() action, String okMsg) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(okMsg), behavior: SnackBarBehavior.floating),
      );
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not finish: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => const _DeleteConfirmDialog(),
    );
    if (ok != true || !mounted) return;

    await _run(() async {
      final session = ref.read(trackingSessionProvider);
      await session.stop();
      await ref.read(dataControlServiceProvider).deleteAllLocalData();
      ref.invalidate(todaysTimelineProvider);
      ref.invalidate(todaysVisitsProvider);
      ref.invalidate(placesByIdProvider);
    }, 'All local data deleted');
  }

  @override
  Widget build(BuildContext context) {
    final c = _counts;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Data and export')),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('On this phone', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Visits'),
                    trailing: Text('${c?.visits ?? '…'}'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Trips'),
                    trailing: Text('${c?.trips ?? '…'}'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Events'),
                    trailing: Text('${c?.events ?? '…'}'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('History cleanup'),
                    subtitle: Text(
                      c == null
                          ? '…'
                          : 'Detailed tracking history older than '
                              '${c.retentionDays} days is removed automatically. '
                              'Visits and trips stay. Change under Tracking.',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Export', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: const Text('Export JSON'),
                    subtitle: const Text(
                      'Visits, trips, places, events and settings.',
                    ),
                    enabled: !_busy,
                    onTap: () => _run(
                      () => ref.read(dataControlServiceProvider).exportJson(),
                      'JSON shared',
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.route_outlined),
                    title: const Text('Export GPX'),
                    subtitle: const Text(
                      'Visit waypoints and trip tracks for map apps.',
                    ),
                    enabled: !_busy,
                    onTap: () => _run(
                      () => ref.read(dataControlServiceProvider).exportGpx(),
                      'GPX shared',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Danger zone', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: Icon(Icons.delete_forever_outlined,
                    color: theme.colorScheme.error),
                title: Text(
                  'Delete all data',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                subtitle: const Text(
                  'Stops tracking and erases local history. Requires typing DELETE.',
                ),
                enabled: !_busy,
                onTap: _confirmDelete,
              ),
            ),
            if (_busy) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }
}

class _DeleteConfirmDialog extends StatefulWidget {
  const _DeleteConfirmDialog();

  @override
  State<_DeleteConfirmDialog> createState() => _DeleteConfirmDialogState();
}

class _DeleteConfirmDialogState extends State<_DeleteConfirmDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete all local data?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'This removes visits, trips, places, events and weather cache '
            'on this phone. Theme and tracking settings stay.\n\n'
            'Type DELETE to confirm.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Type DELETE',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.characters,
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _controller.text.trim().toUpperCase() == 'DELETE'
              ? () => Navigator.pop(context, true)
              : null,
          child: const Text('Delete everything'),
        ),
      ],
    );
  }
}

class _Counts {
  const _Counts({
    required this.visits,
    required this.trips,
    required this.events,
    required this.retentionDays,
  });

  final int visits;
  final int trips;
  final int events;
  final int retentionDays;
}
