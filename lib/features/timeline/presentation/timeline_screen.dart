import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/permissions/permission_providers.dart';
import '../../../core/permissions/permission_service.dart';
import '../../../core/providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/settings/setting_keys.dart';
import '../../../core/widgets/content_width.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/tracking_status_chip.dart';
import '../../../domain/tracking/location_tracker.dart';
import '../../tracking/tracking_providers.dart';

/// S5. Phase 3: live tracking status, pause/resume, point count.
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

  Future<void> _startTracking(WidgetRef ref, TrackingMode mode) async {
    await ref
        .read(settingsRepositoryProvider)
        .write(SettingKeys.trackingEnabled, 'true');
    await ref.read(locationTrackerProvider).start(mode);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perm = ref.watch(locationPermissionProvider);
    final disclosure = ref.watch(backgroundDisclosureShownProvider);
    final trackingPref = ref.watch(trackingEnabledProvider);
    final engineStatus = ref.watch(trackingStatusProvider);
    final pointCount = ref.watch(rawPointCountProvider);
    final modeSetting = ref.watch(trackingModeSettingProvider);

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
    final tracker = ref.read(locationTrackerProvider);
    final lastAt = tracker.lastPointAt;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timeline'),
        actions: [
          if (status == TrackingStatus.on || status == TrackingStatus.paused)
            IconButton(
              tooltip: status == TrackingStatus.on ? 'Pause' : 'Resume',
              icon: Icon(
                status == TrackingStatus.on
                    ? Icons.pause_circle_outline
                    : Icons.play_circle_outline,
              ),
              onPressed: () async {
                if (status == TrackingStatus.on) {
                  await tracker.pause();
                } else {
                  await tracker.resume();
                }
              },
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
            if (count > 0 || lastAt != null) ...[
              const SizedBox(height: 12),
              Text(
                [
                  if (count > 0) '$count point${count == 1 ? '' : 's'} recorded',
                  if (lastAt != null)
                    'Last: ${DateFormat.Hm().format(DateTime.fromMillisecondsSinceEpoch(lastAt, isUtc: true).toLocal())}',
                ].join(' · '),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
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
                    'Project B needs location access to build your timeline. '
                    'You can still use calendar and weather without it.',
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
                    'Turn on background location so places and trips appear '
                    'here automatically, even when the app is closed.',
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
                    '"Allow all the time" in system settings. You can still '
                    'record while the app is open.',
                actionLabel: 'Open settings',
                onAction: () => ref
                    .read(permissionServiceProvider)
                    .openSystemAppSettings(),
              )
            else if (status == TrackingStatus.on ||
                status == TrackingStatus.paused)
              EmptyState(
                icon: Icons.route_outlined,
                title: status == TrackingStatus.on
                    ? 'Recording'
                    : 'Tracking paused',
                message: status == TrackingStatus.on
                    ? 'Points are being saved on this phone. Visits and trips '
                        'will appear after segmentation (next phase). '
                        'On Samsung, exempt the app from battery optimisation '
                        'so tracking survives sleep.'
                    : 'Tap play in the app bar to resume.',
                actionLabel: 'Battery tip',
                onAction: () => context.push(Routes.keepAlive),
              )
            else if (snap != null && snap.hasForeground)
              EmptyState(
                icon: Icons.route_outlined,
                title: count > 0 ? 'Tracking is off' : 'Nothing recorded yet',
                message: count > 0
                    ? 'You have $count saved point${count == 1 ? '' : 's'}. '
                        'Start tracking again to continue.'
                    : 'When tracking is on, points are saved here. Visits and '
                        'trips come in the next phase.',
                actionLabel: 'Start tracking',
                onAction: () async {
                  if (!disclosureShown && snap.hasForeground && !snap.hasBackground) {
                    context.push(Routes.onboardingBackground);
                    return;
                  }
                  await _startTracking(ref, mode);
                },
              )
            else
              const EmptyState(
                icon: Icons.route_outlined,
                title: 'Nothing recorded yet',
                message:
                    'When tracking is on, the places you visit and the trips '
                    'between them appear here.',
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
