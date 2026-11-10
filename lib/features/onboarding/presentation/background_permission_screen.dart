import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/permissions/permission_providers.dart';
import '../../../core/providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/settings/setting_keys.dart';
import '../../../core/widgets/content_width.dart';

/// S3 — prominent disclosure, then system Always / background prompt.
/// Shown when the user taps Start tracking, not on first launch.
/// After this screen runs once, Timeline will not reopen it in a loop.
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

    // Mark disclosure seen up front so a back navigation still breaks the loop.
    await markBackgroundDisclosureShown(ref);

    final bg = await service.requestBackground();
    ref.invalidate(locationPermissionProvider);

    // Phase 2: user opted into tracking. Engine arrives in Phase 3.
    // Persist the intent even if Always was not granted yet (they may
    // finish it in system settings).
    await ref
        .read(settingsRepositoryProvider)
        .write(SettingKeys.trackingEnabled, 'true');

    if (!mounted) return;

    if (!bg.isGranted) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            bg.isPermanentlyDenied
                ? 'Background location is blocked. Open system settings and '
                    'set location to "Allow all the time".'
                : 'For tracking with the app closed, set location to '
                    '"Allow all the time" in system settings.',
          ),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () => service.openSystemAppSettings(),
          ),
        ),
      );
    }

    if (!mounted) return;
    context.go(Routes.timeline);
  }

  Future<void> _notNow() async {
    // Still count as shown so we do not keep forcing this screen.
    await markBackgroundDisclosureShown(ref);
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
          onPressed: _busy ? null : _notNow,
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
                        '(Android) or “Always” (iOS). “While using the app” is '
                        'not enough for a full timeline.',
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
                  onPressed: _busy ? null : _notNow,
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
