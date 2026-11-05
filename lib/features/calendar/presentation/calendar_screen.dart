import 'package:flutter/material.dart';

import '../../../core/widgets/content_width.dart';
import '../../../core/widgets/empty_state.dart';

/// S9. Month and day views arrive in Phase 6.
class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: const ContentWidth(
        child: SingleChildScrollView(
          child: EmptyState(
            icon: Icons.calendar_month_outlined,
            title: 'No events yet',
            message:
                'Your events, reminders and the places you visit will show up '
                'here, day by day.',
          ),
        ),
      ),
    );
  }
}
