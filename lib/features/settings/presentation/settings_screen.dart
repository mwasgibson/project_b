import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/content_width.dart';
import '../../tracking/tracking_providers.dart';
import '../../../domain/tracking/location_tracker.dart';

/// S13.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static String themeLabel(ThemeMode mode) => switch (mode) {
        ThemeMode.system => 'Follows your phone',
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
      };

  static String trackingLabel(TrackingStatus? status) => switch (status) {
        TrackingStatus.on => 'On',
        TrackingStatus.paused => 'Paused',
        TrackingStatus.needsPermission => 'Needs permission',
        TrackingStatus.locationServicesOff => 'Location off',
        TrackingStatus.off || null => 'Off',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider).value ?? ThemeMode.system;
    final tracking = ref.watch(trackingStatusProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.brightness_6_outlined),
                    title: const Text('Appearance'),
                    subtitle: Text(themeLabel(mode)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go(Routes.appearance),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.my_location_outlined),
                    title: const Text('Tracking'),
                    subtitle: Text(trackingLabel(tracking)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(Routes.trackingSettings),
                  ),
                  const Divider(height: 1),
                  const _UnavailableTile(
                    icon: Icons.place_outlined,
                    title: 'Places',
                  ),
                  const Divider(height: 1),
                  const _UnavailableTile(
                    icon: Icons.download_outlined,
                    title: 'Data and export',
                  ),
                  const Divider(height: 1),
                  const _UnavailableTile(
                    icon: Icons.cloud_outlined,
                    title: 'Sync',
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

class _UnavailableTile extends StatelessWidget {
  const _UnavailableTile({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: false,
      leading: Icon(icon),
      title: Text(title),
      subtitle: const Text('Not available yet'),
    );
  }
}
