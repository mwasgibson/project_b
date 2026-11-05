import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/widgets/content_width.dart';

/// S13. Only Appearance works in Phase 1; the rest are listed so the
/// structure from docs/03 is visible, and are disabled until built.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static String themeLabel(ThemeMode mode) => switch (mode) {
        ThemeMode.system => 'Follows your phone',
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider).value ?? ThemeMode.system;

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
                    onTap: () => context.go('/settings/appearance'),
                  ),
                  const Divider(),
                  const _UnavailableTile(
                    icon: Icons.my_location_outlined,
                    title: 'Tracking',
                  ),
                  const Divider(),
                  const _UnavailableTile(
                    icon: Icons.place_outlined,
                    title: 'Places',
                  ),
                  const Divider(),
                  const _UnavailableTile(
                    icon: Icons.download_outlined,
                    title: 'Data and export',
                  ),
                  const Divider(),
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
