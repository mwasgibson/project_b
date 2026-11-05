import 'package:flutter/material.dart';

import '../../domain/tracking/location_tracker.dart';
import '../theme/domain_colors.dart';

/// Always-visible tracking state (docs/04). State is conveyed by an icon and
/// words, never by colour alone.
class TrackingStatusChip extends StatelessWidget {
  const TrackingStatusChip({
    super.key,
    required this.status,
    this.mode,
    this.onTap,
  });

  final TrackingStatus status;

  /// Shown only while tracking is on.
  final TrackingMode? mode;
  final VoidCallback? onTap;

  static String labelFor(TrackingStatus status, TrackingMode? mode) {
    switch (status) {
      case TrackingStatus.on:
        final modeName = switch (mode) {
          TrackingMode.high => 'High precision',
          TrackingMode.balanced => 'Balanced',
          TrackingMode.saver => 'Battery saver',
          null => null,
        };
        return modeName == null ? 'Tracking on' : 'Tracking on · $modeName';
      case TrackingStatus.paused:
        return 'Tracking paused';
      case TrackingStatus.needsPermission:
        return 'Needs location permission';
      case TrackingStatus.locationServicesOff:
        return 'Location services off';
      case TrackingStatus.off:
        return 'Tracking off';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final domain = context.domainColors;
    final label = labelFor(status, mode);

    final (IconData icon, Color iconColor) = switch (status) {
      TrackingStatus.on => (Icons.fiber_manual_record, domain.success),
      TrackingStatus.paused => (Icons.pause_circle_outline, domain.warning),
      TrackingStatus.needsPermission => (
          Icons.warning_amber_rounded,
          domain.warning,
        ),
      TrackingStatus.locationServicesOff => (
          Icons.location_off_outlined,
          domain.warning,
        ),
      TrackingStatus.off => (
          Icons.circle_outlined,
          theme.colorScheme.onSurfaceVariant,
        ),
    };

    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: ShapeDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        shape: StadiumBorder(
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 8),
          Flexible(child: Text(label, style: theme.textTheme.labelLarge)),
        ],
      ),
    );

    return Semantics(
      container: true,
      button: onTap != null,
      label: label,
      child: ExcludeSemantics(
        child: onTap == null
            ? pill
            : InkWell(
                onTap: onTap,
                customBorder: const StadiumBorder(),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Center(widthFactor: 1, child: pill),
                ),
              ),
      ),
    );
  }
}
