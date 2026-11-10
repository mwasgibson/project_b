import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/settings/setting_keys.dart';
import '../../../core/widgets/content_width.dart';
import '../../../domain/tracking/location_tracker.dart';
import '../../tracking/tracking_providers.dart';

/// S14 (partial) — mode + keep-alive. Health/retention land later in Phase 3/8.
class TrackingSettingsScreen extends ConsumerWidget {
  const TrackingSettingsScreen({super.key});

  static String _modeTitle(TrackingMode mode) => switch (mode) {
        TrackingMode.high => 'High precision',
        TrackingMode.balanced => 'Balanced',
        TrackingMode.saver => 'Battery saver',
      };

  static String _modeSubtitle(TrackingMode mode) => switch (mode) {
        TrackingMode.high => 'More points, higher battery use (~10 m).',
        TrackingMode.balanced => 'Default. Good accuracy, moderate battery (~25 m).',
        TrackingMode.saver => 'Fewer updates, lightest on battery (~75 m).',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(trackingModeSettingProvider).valueOrNull ??
        TrackingMode.balanced;
    final status = ref.watch(trackingStatusProvider).valueOrNull ??
        TrackingStatus.off;
    final count = ref.watch(rawPointCountProvider).valueOrNull ?? 0;

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
                  await ref.read(locationTrackerProvider).stop();
                  await ref
                      .read(settingsRepositoryProvider)
                      .write(SettingKeys.trackingEnabled, 'false');
                },
                child: const Text('Stop tracking'),
              ),
          ],
        ),
      ),
    );
  }
}
