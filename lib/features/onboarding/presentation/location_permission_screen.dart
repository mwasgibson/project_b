import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/permissions/permission_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/content_width.dart';

/// S2 — request foreground (while-in-use) location only.
class LocationPermissionScreen extends ConsumerStatefulWidget {
  const LocationPermissionScreen({super.key});

  @override
  ConsumerState<LocationPermissionScreen> createState() =>
      _LocationPermissionScreenState();
}

class _LocationPermissionScreenState
    extends ConsumerState<LocationPermissionScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _request() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final service = ref.read(permissionServiceProvider);
    final status = await service.requestForeground();
    ref.invalidate(locationPermissionProvider);

    if (!mounted) return;

    if (status.isGranted || status.isLimited) {
      await markOnboardingCompleted(ref);
      if (!mounted) return;
      context.go(Routes.timeline);
      return;
    }

    // Denied or permanently denied: still finish onboarding; Timeline explains.
    await markOnboardingCompleted(ref);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = status.isPermanentlyDenied
          ? 'Location was blocked. You can enable it later in Settings.'
          : 'Location was not granted. You can still use the calendar and weather.';
    });
    context.go(Routes.timeline);
  }

  Future<void> _skip() async {
    await markOnboardingCompleted(ref);
    if (!mounted) return;
    context.go(Routes.timeline);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: ContentWidth(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Icon(
                  Icons.my_location_outlined,
                  size: 56,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Allow location while using the app',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'This lets Project B show where you are on the map and label '
                  'places when you are looking at the app. Background tracking '
                  'is a separate step you control later.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const Spacer(),
                FilledButton(
                  onPressed: _busy ? null : _request,
                  child: _busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Allow location'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _busy ? null : _skip,
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
