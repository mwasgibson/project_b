import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/permissions/permission_providers.dart';
import '../../../core/permissions/permission_service.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/content_width.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/tracking_status_chip.dart';
import '../../../domain/tracking/location_tracker.dart';

/// S5. Phase 2 wires permission state; live timeline arrives in Phases 3–4.
class TimelineScreen extends ConsumerWidget {
  const TimelineScreen({super.key});

  TrackingStatus _statusFrom({
    required LocationPermissionSnapshot? snap,
    required bool trackingEnabled,
  }) {
    if (snap == null) return TrackingStatus.off;
    if (!snap.serviceEnabled) return TrackingStatus.locationServicesOff;
    if (!snap.hasForeground) return TrackingStatus.needsPermission;
    // Engine is Phase 3; until then stay "off" even when permissions are ready.
    if (trackingEnabled && snap.hasForeground) return TrackingStatus.off;
    return TrackingStatus.off;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perm = ref.watch(locationPermissionProvider);
    final disclosure = ref.watch(backgroundDisclosureShownProvider);
    final tracking = ref.watch(trackingEnabledProvider);

    final snap = perm.valueOrNull;
    final disclosureShown = disclosure.valueOrNull ?? false;
    final trackingEnabled = tracking.valueOrNull ?? false;
    final status = _statusFrom(snap: snap, trackingEnabled: trackingEnabled);

    return Scaffold(
      appBar: AppBar(title: const Text('Timeline')),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TrackingStatusChip(
                status: status,
                onTap: () {
                  // Only open S3 the first time; afterwards send to settings.
                  if (snap != null &&
                      snap.hasForeground &&
                      !snap.hasBackground &&
                      !disclosureShown) {
                    context.push(Routes.onboardingBackground);
                  }
                },
              ),
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
              // First time only: offer the disclosure + system prompt.
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
                disclosureShown)
              // Already went through S3; do not loop — send to system settings.
              _PermissionCard(
                title: 'Allow all the time',
                message:
                    'Tracking with the app closed needs "Allow all the time" '
                    '(Android) or "Always" (iOS). Open system settings for '
                    'Project B and set location access there.',
                actionLabel: 'Open settings',
                onAction: () => ref
                    .read(permissionServiceProvider)
                    .openSystemAppSettings(),
              )
            else
              EmptyState(
                icon: Icons.route_outlined,
                title: trackingEnabled
                    ? 'Tracking is ready'
                    : 'Nothing recorded yet',
                message: trackingEnabled
                    ? 'Permissions look good. The tracking engine arrives in '
                        'the next phase — for now nothing is written yet.'
                    : 'When tracking is on, the places you visit and the trips '
                        'between them appear here.',
                actionLabel:
                    trackingEnabled || disclosureShown ? null : 'Start tracking',
                onAction: trackingEnabled || disclosureShown
                    ? null
                    : () => context.push(Routes.onboardingBackground),
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
