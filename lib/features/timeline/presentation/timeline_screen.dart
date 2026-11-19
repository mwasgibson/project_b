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

/// S5 — tracking controls + today's story (visits, trips, gaps).
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

  static String _gapLabel(String reason) => switch (reason) {
        'paused' => 'Tracking paused',
        'permission' => 'Location not available',
        'off' => 'Tracking was off',
        _ => 'No location data',
      };

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
    final entries = timelineAsync.valueOrNull ?? const <TimelineEntry>[];
    final visitCount =
        entries.where((e) => e.kind == TimelineEntryKind.visit).length;
    final tripCount =
        entries.where((e) => e.kind == TimelineEntryKind.trip).length;
    final timeFmt = DateFormat.Hm();
    final domain = context.domainColors;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timeline'),
        actions: [
          IconButton(
            tooltip: 'Refresh timeline',
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
        ],
      ),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TrackingStatusChip(
                status: status,
                mode: status == TrackingStatus.on ? mode : null,
                onTap: () => context.push(Routes.trackingSettings),
              ),
            ),
            if (visitCount > 0 || tripCount > 0) ...[
              const SizedBox(height: 12),
              Text(
                [
                  if (visitCount > 0)
                    '$visitCount place${visitCount == 1 ? '' : 's'}',
                  if (tripCount > 0)
                    '$tripCount trip${tripCount == 1 ? '' : 's'}',
                ].join(' · '),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
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
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                      child: ListTile(
                        leading: Icon(
                          Icons.warning_amber_rounded,
                          color: theme.colorScheme.onErrorContainer,
                        ),
                        title: Text(
                          'No location for over 30 minutes',
                          style: TextStyle(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                        subtitle: Text(
                          'Some phones limit background apps. Check the battery tip.',
                          style: TextStyle(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                        onTap: () => context.push(Routes.keepAlive),
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 20),
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
              Text('Today', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              for (var i = 0; i < entries.length; i++)
                _TimelineRow(
                  entry: entries[i],
                  isFirst: i == 0,
                  isLast: i == entries.length - 1,
                  timeFmt: timeFmt,
                  placesMap: placesMap,
                  domain: domain,
                  formatDuration: _formatDuration,
                  formatDistance: _formatDistance,
                  visitTitle: _visitTitle,
                  gapLabel: _gapLabel,
                  onVisitTap: (v) => VisitDetailSheet.show(
                    context,
                    v,
                    place: v.placeId == null ? null : placesMap[v.placeId!],
                  ),
                ),
              if (status != TrackingStatus.on &&
                  status != TrackingStatus.paused)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextButton(
                    onPressed: () => session.start(mode),
                    child: const Text('Start tracking'),
                  ),
                ),
            ] else if (status == TrackingStatus.on ||
                status == TrackingStatus.paused)
              EmptyState(
                icon: Icons.route_outlined,
                title: status == TrackingStatus.on
                    ? 'Recording your day'
                    : 'Tracking paused',
                message: status == TrackingStatus.on
                    ? 'Stay somewhere a few minutes, then pull refresh. '
                        'Same places stay as one visit even if you pause.'
                    : 'Tap play to resume, or stop tracking fully.',
                actionLabel: 'Refresh timeline',
                onAction: () => _findVisits(context, ref),
              )
            else if (snap != null && snap.hasForeground)
              EmptyState(
                icon: Icons.route_outlined,
                title: 'Nothing recorded yet',
                message:
                    'When tracking is on, the places you stay become visits here.',
                actionLabel: 'Start tracking',
                onAction: () async {
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

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.entry,
    required this.isFirst,
    required this.isLast,
    required this.timeFmt,
    required this.placesMap,
    required this.domain,
    required this.formatDuration,
    required this.formatDistance,
    required this.visitTitle,
    required this.gapLabel,
    required this.onVisitTap,
  });

  final TimelineEntry entry;
  final bool isFirst;
  final bool isLast;
  final DateFormat timeFmt;
  final Map<String, Place> placesMap;
  final DomainColors domain;
  final String Function(int, int?) formatDuration;
  final String Function(double?) formatDistance;
  final String Function(Visit, Map<String, Place>) visitTitle;
  final String Function(String) gapLabel;
  final void Function(Visit) onVisitTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Color railColor;
    final IconData icon;
    final String title;
    final String subtitle;
    final VoidCallback? onTap;

    switch (entry.kind) {
      case TimelineEntryKind.visit:
        final v = entry.visit!;
        railColor = domain.visit;
        icon = Icons.place;
        title = visitTitle(v, placesMap);
        subtitle =
            '${timeFmt.format(DateTime.fromMillisecondsSinceEpoch(v.startAt, isUtc: true).toLocal())}'
            ' – '
            '${v.endAt == null ? 'now' : timeFmt.format(DateTime.fromMillisecondsSinceEpoch(v.endAt!, isUtc: true).toLocal())}'
            ' · ${formatDuration(v.startAt, v.endAt)}';
        onTap = () => onVisitTap(v);
      case TimelineEntryKind.trip:
        final t = entry.trip!;
        railColor = domain.trip;
        icon = Icons.directions;
        title = 'Trip';
        subtitle = [
          '${timeFmt.format(DateTime.fromMillisecondsSinceEpoch(t.startAt, isUtc: true).toLocal())}'
              ' – '
              '${timeFmt.format(DateTime.fromMillisecondsSinceEpoch(t.endAt, isUtc: true).toLocal())}',
          formatDuration(t.startAt, t.endAt),
          if (t.distanceM != null) formatDistance(t.distanceM),
        ].join(' · ');
        onTap = null;
      case TimelineEntryKind.gap:
        final g = entry.gap!;
        railColor = domain.gap;
        icon = Icons.more_horiz;
        title = gapLabel(g.reason);
        subtitle =
            '${timeFmt.format(DateTime.fromMillisecondsSinceEpoch(g.startAt, isUtc: true).toLocal())}'
            ' – '
            '${timeFmt.format(DateTime.fromMillisecondsSinceEpoch(g.endAt, isUtc: true).toLocal())}'
            ' · ${formatDuration(g.startAt, g.endAt)}';
        onTap = null;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: 2,
                    color: isFirst
                        ? Colors.transparent
                        : railColor.withValues(alpha: 0.35),
                  ),
                ),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: railColor, width: 2),
                  ),
                  child: Icon(icon, size: 12, color: railColor),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast
                        ? Colors.transparent
                        : railColor.withValues(alpha: 0.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: entry.kind == TimelineEntryKind.gap
                    ? theme.colorScheme.surfaceContainerHighest
                    : theme.colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: entry.kind == TimelineEntryKind.gap
                                      ? theme.colorScheme.onSurfaceVariant
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                subtitle,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (onTap != null)
                          Icon(
                            Icons.chevron_right,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
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
