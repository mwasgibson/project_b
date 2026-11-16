import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/settings/setting_keys.dart';
import '../../../core/widgets/content_width.dart';
import '../../../domain/tracking/location_tracker.dart';
import '../../tracking/tracking_providers.dart';

/// S14 — mode, auto-saver, health, keep-alive.
class TrackingSettingsScreen extends ConsumerWidget {
  const TrackingSettingsScreen({super.key});

  static String _modeTitle(TrackingMode mode) => switch (mode) {
        TrackingMode.high => 'High precision',
        TrackingMode.balanced => 'Balanced',
        TrackingMode.saver => 'Battery saver',
      };

  static String _modeSubtitle(TrackingMode mode) => switch (mode) {
        TrackingMode.high => 'More points, higher battery use (~10 m).',
        TrackingMode.balanced =>
          'Default. Good accuracy, moderate battery (~25 m).',
        TrackingMode.saver => 'Fewer updates, lightest on battery (~75 m).',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(trackingModeSettingProvider).valueOrNull ??
        TrackingMode.balanced;
    final status = ref.watch(trackingStatusProvider).valueOrNull ??
        TrackingStatus.off;
    final count = ref.watch(rawPointCountProvider).valueOrNull ?? 0;
    final autoSaver = ref.watch(autoSaverEnabledProvider).valueOrNull ?? true;
    final level = ref.watch(autoSaverLevelProvider).valueOrNull ?? 20;
    final session = ref.watch(trackingSessionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tracking')),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
                      await ref
                          .read(settingsRepositoryProvider)
                          .write(
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
              'Status',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Engine'),
                    subtitle: Text(status.name),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Points on this phone'),
                    subtitle: Text('$count'),
                  ),
                  const Divider(height: 1),
                  FutureBuilder<String?>(
                    future: session.healthLabel(),
                    builder: (context, snap) {
                      return ListTile(
                        title: const Text('Health'),
                        subtitle: Text(
                          snap.data ??
                              (status == TrackingStatus.on
                                  ? 'Waiting for first point…'
                                  : 'Not tracking'),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Samsung / battery tip'),
                    subtitle: const Text(
                      'Exempt Project B from battery optimisation so tracking survives sleep.',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(Routes.keepAlive),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (status == TrackingStatus.on || status == TrackingStatus.paused)
              OutlinedButton(
                onPressed: () async {
                  await ref.read(trackingSessionProvider).stop();
                },
                child: const Text('Stop tracking'),
              ),
          ],
        ),
      ),
    );
  }
}
