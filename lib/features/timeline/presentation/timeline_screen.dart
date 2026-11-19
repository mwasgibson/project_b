import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/db/app_database.dart';
import '../../../core/permissions/permission_providers.dart';
import '../../../core/permissions/permission_service.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/domain_colors.dart';
import '../../../core/widgets/content_width.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/tracking_status_chip.dart';
import '../../../domain/timeline/timeline_entry.dart';
import '../../../domain/tracking/location_tracker.dart';
import '../../tracking/tracking_providers.dart';
import 'visit_detail_sheet.dart';

/// S5 — tracking controls + today's visits and trips.
class TimelineScreen extends ConsumerWidget {
  const TimelineScreen({super.key});

  TrackingStatus _combined({
    required LocationPermissionSnapshot? snap,
    required TrackingStatus? engine,
    required bool trackingEnabled,
  }) {
    if (snap == null) return engine ?? TrackingStatus.off;
    if (!snap.serviceEnabled) return TrackingStatus.locationServicesOff;
    if (!snap.hasForeground) return TrackingStatus.needsPermission;
    if (engine != null && engine != TrackingStatus.off) return engine;
    if (trackingEnabled) return TrackingStatus.off;
    return TrackingStatus.off;
  }

  static String _formatDuration(int startMs, int? endMs) {
    if (endMs == null) return 'ongoing';
    final d = Duration(milliseconds: endMs - startMs);
    if (d.inHours >= 1) {
      final m = d.inMinutes.remainder(60);
      return m == 0 ? '${d.inHours} h' : '${d.inHours} h $m min';
    }
    if (d.inMinutes < 1) return '<1 min';
    return '${d.inMinutes} min';
  }

  static String _formatDistance(double? meters) {
    if (meters == null) return '';
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.round()} m';
  }

  static String _visitTitle(Visit v, Map<String, Place> places) {
    final id = v.placeId;
    if (id != null) {
      final name = places[id]?.name?.trim();
      if (name != null && name.isNotEmpty) return name;
    }
    return switch (v.labelState) {
      'pending' => 'Labelling…',
      'failed' => 'Unknown place',
      'disabled' => 'Unlabelled place',
      _ => 'Unknown place',
    };
  }

  Future<void> _findVisits(BuildContext context, WidgetRef ref) async {
    final msg = await runSegmentation(ref);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(trackingSessionProvider);

    final perm = ref.watch(locationPermissionProvider);
    final disclosure = ref.watch(backgroundDisclosureShownProvider);
    final trackingPref = ref.watch(trackingEnabledProvider);
    final engineStatus = ref.watch(trackingStatusProvider);
    final pointCount = ref.watch(rawPointCountProvider);
    final modeSetting = ref.watch(trackingModeSettingProvider);
    final timelineAsync = ref.watch(todaysTimelineProvider);
    final placesMap = ref.watch(placesByIdProvider).valueOrNull ?? {};

    final snap = perm.valueOrNull;
    final disclosureShown = disclosure.valueOrNull ?? false;
    final trackingEnabled = trackingPref.valueOrNull ?? false;
    final engine = engineStatus.valueOrNull;
    final mode = modeSetting.valueOrNull ?? TrackingMode.balanced;
    final status = _combined(
      snap: snap,
      engine: engine,
      trackingEnabled: trackingEnabled,
    );
    final count = pointCount.valueOrNull ?? 0;
    final lastAt = session.tracker.lastPointAt;
    final entries = timelineAsync.valueOrNull ?? const <TimelineEntry>[];
    final visitCount =
        entries.where((e) => e.kind == TimelineEntryKind.visit).length;
    final tripCount =
        entries.where((e) => e.kind == TimelineEntryKind.trip).length;
    final timeFmt = DateFormat.Hm();
    final domain = context.domainColors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timeline'),
        actions: [
          IconButton(
            tooltip: 'Find visits',
            icon: const Icon(Icons.refresh),
            onPressed: () => _findVisits(context, ref),
          ),
          if (status == TrackingStatus.on)
            IconButton(
              tooltip: 'Pause',
              icon: const Icon(Icons.pause_circle_outline),
              onPressed: () => session.pause(),
            ),
          if (status == TrackingStatus.paused)
            IconButton(
              tooltip: 'Resume',
              icon: const Icon(Icons.play_circle_outline),
              onPressed: () => session.resume(),
            ),
          if (status == TrackingStatus.on || status == TrackingStatus.paused)
            IconButton(
              tooltip: 'Stop tracking',
              icon: const Icon(Icons.stop_circle_outlined),
              onPressed: () => session.stop(),
            ),
          IconButton(
            tooltip: 'Tracking settings',
            icon: const Icon(Icons.tune),
            onPressed: () => context.push(Routes.trackingSettings),
          ),
        ],
      ),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TrackingStatusChip(
                status: status,
                mode: status == TrackingStatus.on ? mode : null,
                onTap: () => context.push(Routes.trackingSettings),
              ),
            ),
            if (count > 0 || lastAt != null || entries.isNotEmpty) ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: count > 0 ? () => context.push(Routes.points) : null,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    [
                      if (count > 0) '$count point${count == 1 ? '' : 's'}',
                      if (visitCount > 0)
                        '$visitCount visit${visitCount == 1 ? '' : 's'}',
                      if (tripCount > 0)
                        '$tripCount trip${tripCount == 1 ? '' : 's'}',
                      if (lastAt != null)
                        'Last: ${timeFmt.format(DateTime.fromMillisecondsSinceEpoch(lastAt, isUtc: true).toLocal())}',
                    ].join(' · '),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                          decoration: count > 0
                              ? TextDecoration.underline
                              : null,
                          decorationColor: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                  ),
                ),
              ),
            ],
            if (status == TrackingStatus.on)
              FutureBuilder<bool>(
                future: session.isStale(),
                builder: (context, staleSnap) {
                  if (staleSnap.data != true) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Material(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                      child: ListTile(
                        leading: Icon(
                          Icons.warning_amber_rounded,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                        title: Text(
                          'No points for over 30 minutes',
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                        subtitle: Text(
                          'Some phones limit background apps. Check the battery tip.',
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                        onTap: () => context.push(Routes.keepAlive),
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 16),
            if (snap != null && !snap.serviceEnabled)
              _PermissionCard(
                title: 'Location services are off',
                message:
                    'Turn on location in your phone settings so Project B can record visits.',
                actionLabel: 'Open settings',
                onAction: () => ref
                    .read(permissionServiceProvider)
                    .openSystemAppSettings(),
              )
            else if (snap != null && !snap.hasForeground)
              _PermissionCard(
                title: 'Location permission needed',
                message:
                    'Project B needs location access to build your timeline.',
                actionLabel: snap.foregroundPermanentlyDenied
                    ? 'Open settings'
                    : 'Allow location',
                onAction: () async {
                  if (snap.foregroundPermanentlyDenied) {
                    await ref
                        .read(permissionServiceProvider)
                        .openSystemAppSettings();
                  } else {
                    await ref
                        .read(permissionServiceProvider)
                        .requestForeground();
                    ref.invalidate(locationPermissionProvider);
                  }
                },
              )
            else if (snap != null &&
                snap.hasForeground &&
                !snap.hasBackground &&
                !disclosureShown)
              _PermissionCard(
                title: 'Start tracking',
                message:
                    'Turn on background location so places and trips appear automatically.',
                actionLabel: 'Start tracking',
                onAction: () => context.push(Routes.onboardingBackground),
              )
            else if (snap != null &&
                snap.hasForeground &&
                !snap.hasBackground &&
                disclosureShown &&
                status != TrackingStatus.on &&
                status != TrackingStatus.paused)
              _PermissionCard(
                title: 'Allow all the time',
                message:
                    'For tracking with the app closed, set location to '
                    '"Allow all the time" in system settings.',
                actionLabel: 'Open settings',
                onAction: () => ref
                    .read(permissionServiceProvider)
                    .openSystemAppSettings(),
              )
            else if (entries.isNotEmpty) ...[
              Text(
                'Today',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              for (final entry in entries)
                if (entry.kind == TimelineEntryKind.visit)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        Icons.place_outlined,
                        color: domain.visit,
                      ),
                      title: Text(_visitTitle(entry.visit!, placesMap)),
                      subtitle: Text(
                        '${timeFmt.format(DateTime.fromMillisecondsSinceEpoch(entry.visit!.startAt, isUtc: true).toLocal())}'
                        ' – '
                        '${entry.visit!.endAt == null ? 'now' : timeFmt.format(DateTime.fromMillisecondsSinceEpoch(entry.visit!.endAt!, isUtc: true).toLocal())}'
                        ' · ${_formatDuration(entry.visit!.startAt, entry.visit!.endAt)}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => VisitDetailSheet.show(
                        context,
                        entry.visit!,
                        place: entry.visit!.placeId == null
                            ? null
                            : placesMap[entry.visit!.placeId!],
                      ),
                    ),
                  )
                else
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        Icons.directions_outlined,
                        color: domain.trip,
                      ),
                      title: const Text('Trip'),
                      subtitle: Text(
                        [
                          '${timeFmt.format(DateTime.fromMillisecondsSinceEpoch(entry.trip!.startAt, isUtc: true).toLocal())}'
                              ' – '
                              '${timeFmt.format(DateTime.fromMillisecondsSinceEpoch(entry.trip!.endAt, isUtc: true).toLocal())}',
                          _formatDuration(
                            entry.trip!.startAt,
                            entry.trip!.endAt,
                          ),
                          if (entry.trip!.distanceM != null)
                            _formatDistance(entry.trip!.distanceM),
                        ].join(' · '),
                      ),
                    ),
                  ),
              if (status != TrackingStatus.on &&
                  status != TrackingStatus.paused)
                TextButton(
                  onPressed: () => session.start(mode),
                  child: const Text('Start tracking'),
                ),
            ] else if (status == TrackingStatus.on ||
                status == TrackingStatus.paused)
              EmptyState(
                icon: Icons.route_outlined,
                title: status == TrackingStatus.on
                    ? 'Recording'
                    : 'Tracking paused',
                message: status == TrackingStatus.on
                    ? 'Stay in one place a few minutes, then tap Find visits. '
                        'Automatic visits use ~10 minutes; Find visits is more lenient.'
                    : 'Tap play in the app bar to resume, or stop tracking fully.',
                actionLabel: 'Find visits',
                onAction: () => _findVisits(context, ref),
              )
            else if (snap != null && snap.hasForeground)
              EmptyState(
                icon: Icons.route_outlined,
                title:
                    count > 0 ? 'No visits yet today' : 'Nothing recorded yet',
                message: count > 0
                    ? 'You have points saved. Tap Find visits to turn them into '
                        'places (about 2 minutes in one spot is enough).'
                    : 'When tracking is on, the places you stay become visits here.',
                actionLabel: count > 0 ? 'Find visits' : 'Start tracking',
                onAction: () async {
                  if (count > 0) {
                    await _findVisits(context, ref);
                    return;
                  }
                  if (!disclosureShown &&
                      snap.hasForeground &&
                      !snap.hasBackground) {
                    await context.push(Routes.onboardingBackground);
                    return;
                  }
                  await session.start(mode);
                },
              )
            else
              const EmptyState(
                icon: Icons.route_outlined,
                title: 'Nothing recorded yet',
                message:
                    'When tracking is on, the places you visit appear here.',
              ),
          ],
        ),
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.my_location_outlined,
      title: title,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}
