import 'package:flutter/material.dart';

import '../../../core/widgets/content_width.dart';
import '../../../core/widgets/empty_state.dart';

/// S12. Forecast arrives in Phase 7.
class WeatherScreen extends StatelessWidget {
  const WeatherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Weather')),
      body: const ContentWidth(
        child: SingleChildScrollView(
          child: EmptyState(
            icon: Icons.wb_cloudy_outlined,
            title: 'No forecast yet',
            message: 'The forecast for where you are will appear here.',
          ),
        ),
      ),
    );
  }
}
