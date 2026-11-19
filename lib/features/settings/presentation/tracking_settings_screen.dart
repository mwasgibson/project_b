import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/settings/setting_keys.dart';
import '../../../core/widgets/content_width.dart';
import '../../../domain/tracking/location_tracker.dart';
import '../../data/data_control_providers.dart';
import '../../tracking/tracking_providers.dart';

/// S14 — on/off, mode, auto-saver, auto-label, retention, last update, battery tip.
class TrackingSettingsScreen extends ConsumerWidget {
  const TrackingSettingsScreen({super.key});

  static String _modeTitle(TrackingMode mode) => switch (mode) {
        TrackingMode.high => 'High precision',
        TrackingMode.balanced => 'Balanced',
        TrackingMode.saver => 'Battery saver',
      };

  static String _modeSubtitle(TrackingMode mode) => switch (mode) {
        TrackingMode.high => 'More detail, higher battery use.',
        TrackingMode.balanced => 'Default. Good balance of detail and battery.',
        TrackingMode.saver => 'Fewer updates, lightest on battery.',
      };

  static String _statusLabel(TrackingStatus status) => switch (status) {
        TrackingStatus.on => 'Recording',
        TrackingStatus.paused => 'Paused',
        TrackingStatus.needsPermission => 'Needs permission',
        TrackingStatus.locationServicesOff => 'Location services off',
        TrackingStatus.off => 'Off',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(trackingModeSettingProvider).valueOrNull ??
        TrackingMode.balanced;
    final status = ref.watch(trackingStatusProvider).valueOrNull ??
        TrackingStatus.off;
    final autoSaver = ref.watch(autoSaverEnabledProvider).valueOrNull ?? true;
    final level = ref.watch(autoSaverLevelProvider).valueOrNull ?? 20;
    final autoLabel = ref.watch(autoLabelEnabledProvider).valueOrNull ?? true;
    final retention = ref.watch(rawRetentionDaysProvider).valueOrNull ?? 30;
    final session = ref.watch(trackingSessionProvider);
    final trackingOn =
        status == TrackingStatus.on || status == TrackingStatus.paused;

    return Scaffold(
      appBar: AppBar(title: const Text('Tracking')),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Tracking', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Track location'),
                    subtitle: Text(_statusLabel(status)),
                    value: trackingOn,
                    onChanged: (on) async {
                      if (on) {
                        await session.start(mode);
                      } else {
                        await session.stop();
                      }
                    },
                  ),
                  if (status == TrackingStatus.on) ...[
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('Pause'),
                      subtitle: const Text(
                        'Stops recording temporarily. Same place stays one visit when you resume.',
                      ),
                      trailing: const Icon(Icons.pause_circle_outline),
                      onTap: () => session.pause(),
                    ),
                  ],
                  if (status == TrackingStatus.paused) ...[
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('Resume'),
                      trailing: const Icon(Icons.play_circle_outline),
                      onTap: () => session.resume(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Battery mode',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  for (final m in TrackingMode.values) ...[
                    if (m != TrackingMode.values.first) const Divider(height: 1),
                    RadioListTile<TrackingMode>(
                      value: m,
                      groupValue: mode,
                      title: Text(_modeTitle(m)),
                      subtitle: Text(_modeSubtitle(m)),
                      onChanged: (value) async {
                        if (value == null) return;
                        await setTrackingModeSetting(ref, value);
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Auto battery saver',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Switch to saver when battery is low'),
                    subtitle: Text('Uses saver mode at or below $level%'),
                    value: autoSaver,
                    onChanged: (on) async {
                      await ref.read(settingsRepositoryProvider).write(
                            SettingKeys.autoSaverEnabled,
                            on ? 'true' : 'false',
                          );
                    },
                  ),
                  if (autoSaver) ...[
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('Threshold'),
                      subtitle: Text('$level%'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: level <= 5
                                ? null
                                : () async {
                                    await ref
                                        .read(settingsRepositoryProvider)
                                        .write(
                                          SettingKeys.autoSaverLevel,
                                          '${level - 5}',
                                        );
                                  },
                            icon: const Icon(Icons.remove),
                          ),
                          IconButton(
                            onPressed: level >= 50
                                ? null
                                : () async {
                                    await ref
                                        .read(settingsRepositoryProvider)
                                        .write(
                                          SettingKeys.autoSaverLevel,
                                          '${level + 5}',
                                        );
                                  },
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Place names',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Card(
              child: SwitchListTile(
                title: const Text('Auto-label visits'),
                subtitle: const Text(
                  'Uses the phone’s place service. Coordinates may be sent to '
                  'the platform vendor. Turn off to keep visits unlabelled.',
                ),
                value: autoLabel,
                onChanged: (on) async {
                  await ref.read(settingsRepositoryProvider).write(
                        SettingKeys.autoLabelEnabled,
                        on ? 'true' : 'false',
                      );
                  if (on) {
                    await ref.read(placeLabelServiceProvider).processPending();
                    ref.invalidate(todaysTimelineProvider);
                    ref.invalidate(placesByIdProvider);
                  }
                },
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'History retention',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                title: const Text('Keep detailed history for'),
                subtitle: Text(
                  '$retention days. Your visits and trips are kept longer.',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: retention <= 7
                          ? null
                          : () async {
                              await ref
                                  .read(dataControlServiceProvider)
                                  .setRetentionDays(retention - 7);
                              await ref
                                  .read(dataControlServiceProvider)
                                  .purgeExpiredRawPoints();
                              ref.invalidate(rawRetentionDaysProvider);
                            },
                      icon: const Icon(Icons.remove),
                    ),
                    IconButton(
                      onPressed: retention >= 365
                          ? null
                          : () async {
                              await ref
                                  .read(dataControlServiceProvider)
                                  .setRetentionDays(retention + 7);
                              ref.invalidate(rawRetentionDaysProvider);
                            },
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Status', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  FutureBuilder<String?>(
                    future: session.healthLabel(),
                    builder: (context, snap) {
                      return ListTile(
                        title: const Text('Last location update'),
                        subtitle: Text(
                          snap.data ??
                              (status == TrackingStatus.on
                                  ? 'Waiting for the first update…'
                                  : 'None while tracking is off'),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Battery tip'),
                    subtitle: const Text(
                      'Some phones limit apps in the background. '
                      'Allow unrestricted battery use so tracking can keep running.',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(Routes.keepAlive),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
