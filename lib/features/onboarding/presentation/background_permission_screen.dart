import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/permissions/permission_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/settings/setting_keys.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/content_width.dart';

/// S3 — prominent disclosure, then system Always / background prompt.
/// Shown when the user taps Start tracking, not on first launch.
class BackgroundPermissionScreen extends ConsumerStatefulWidget {
  const BackgroundPermissionScreen({super.key});

  @override
  ConsumerState<BackgroundPermissionScreen> createState() =>
      _BackgroundPermissionScreenState();
}

class _BackgroundPermissionScreenState
    extends ConsumerState<BackgroundPermissionScreen> {
  bool _busy = false;

  Future<void> _continue() async {
    setState(() => _busy = true);
    final service = ref.read(permissionServiceProvider);

    // Ensure foreground first (Android requires this order).
    final fg = await service.requestForeground();
    if (!fg.isGranted && !fg.isLimited) {
      ref.invalidate(locationPermissionProvider);
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Foreground location is required before background tracking.',
          ),
        ),
      );
      return;
    }

    final bg = await service.requestBackground();
    ref.invalidate(locationPermissionProvider);

    if (bg.isGranted) {
      await ref
          .read(settingsRepositoryProvider)
          .write(SettingKeys.trackingEnabled, 'true');
    }

    if (!mounted) return;
    context.go(Routes.timeline);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Background location'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go(Routes.timeline),
        ),
      ),
      body: SafeArea(
        child: ContentWidth(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      Icon(
                        Icons.location_searching,
                        size: 48,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Allow location in the background',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Project B needs background location so it can record '
                        'where you go even when the app is closed or the screen '
                        'is off. That is how your timeline fills in without you '
                        'logging anything.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Data stays on this phone. You can pause tracking from '
                        'the home screen or delete everything in Settings.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'On the next screen, choose “Allow all the time” '
                        '(Android) or “Always” (iOS). Anything less means '
                        'tracking will stop when you leave the app.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: _busy ? null : _continue,
                  child: _busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Continue'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _busy ? null : () => context.go(Routes.timeline),
                  child: const Text('Not now'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
