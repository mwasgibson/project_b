import 'package:flutter/material.dart';

import '../../../core/widgets/content_width.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/tracking_status_chip.dart';
import '../../../domain/tracking/location_tracker.dart';

/// S5. Phase 1 shows the empty state; the live timeline arrives with
/// tracking (Phase 3) and segmentation (Phase 4).
class TimelineScreen extends StatelessWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Timeline')),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            Align(
              alignment: Alignment.centerLeft,
              child: TrackingStatusChip(status: TrackingStatus.off),
            ),
            SizedBox(height: 16),
            EmptyState(
              icon: Icons.route_outlined,
              title: 'Nothing recorded yet',
              message:
                  'When tracking is on, the places you visit and the trips '
                  'between them appear here.',
            ),
          ],
        ),
      ),
    );
  }
}
