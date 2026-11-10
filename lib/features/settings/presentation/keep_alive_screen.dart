import 'package:flutter/material.dart';

import '../../../core/widgets/content_width.dart';

/// S22 — Samsung / aggressive OEM battery guide (docs/03).
class KeepAliveScreen extends StatelessWidget {
  const KeepAliveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Keep tracking alive')),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Samsung and some other phones stop apps to save battery. '
              'That can leave gaps in your timeline even when tracking is on.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Text('On Samsung (One UI)', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            const _Step(
              n: 1,
              text:
                  'Open Settings → Apps → Project B → Battery (or App battery usage).',
            ),
            const _Step(
              n: 2,
              text: 'Choose Unrestricted (not Optimised or Restricted).',
            ),
            const _Step(
              n: 3,
              text:
                  'In Settings → Battery → Background usage limits, make sure Project B is not sleeping or deep-sleeping.',
            ),
            const _Step(
              n: 4,
              text:
                  'Optional: lock the app in Recents so One UI is less likely to kill it.',
            ),
            const SizedBox(height: 24),
            Text('Also check',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              '• Location permission is "Allow all the time".\n'
              '• Location services are on.\n'
              '• After a reboot, open Project B once if tracking did not resume.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'A persistent notification for tracking will arrive in a later '
              'update (foreground service). Until then, unrestricted battery '
              'and Always location are the main levers on Samsung.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.n, required this.text});

  final int n;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            child: Text('$n', style: const TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
