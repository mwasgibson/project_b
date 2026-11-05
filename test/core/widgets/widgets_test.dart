import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_b/app.dart';
import 'package:project_b/core/providers.dart';
import 'package:project_b/core/theme/app_theme.dart';
import 'package:project_b/core/widgets/empty_state.dart';
import 'package:project_b/core/widgets/tracking_status_chip.dart';
import 'package:project_b/domain/tracking/location_tracker.dart';

Widget _host(Widget child, {ThemeData? theme}) => MaterialApp(
      theme: theme ?? AppTheme.light,
      home: Scaffold(body: child),
    );

void main() {
  group('TrackingStatusChip', () {
    test('every status has distinct wording (not colour alone)', () {
      final labels = TrackingStatus.values
          .map((s) => TrackingStatusChip.labelFor(s, null))
          .toSet();
      expect(labels.length, TrackingStatus.values.length);
    });

    test('shows the mode only while tracking is on', () {
      expect(
        TrackingStatusChip.labelFor(TrackingStatus.on, TrackingMode.balanced),
        'Tracking on · Balanced',
      );
      expect(
        TrackingStatusChip.labelFor(TrackingStatus.paused, TrackingMode.high),
        'Tracking paused',
      );
    });

    testWidgets('renders its label in light and dark themes', (tester) async {
      for (final theme in [AppTheme.light, AppTheme.dark]) {
        await tester.pumpWidget(
          _host(
            const TrackingStatusChip(
              status: TrackingStatus.on,
              mode: TrackingMode.saver,
            ),
            theme: theme,
          ),
        );
        expect(find.text('Tracking on · Battery saver'), findsOneWidget);
      }
    });
  });

  group('EmptyState', () {
    testWidgets('shows title and message, and an action when given',
        (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _host(
          EmptyState(
            icon: Icons.route_outlined,
            title: 'Nothing here',
            message: 'Add something.',
            actionLabel: 'Add',
            onAction: () => tapped = true,
          ),
        ),
      );
      expect(find.text('Nothing here'), findsOneWidget);
      expect(find.text('Add something.'), findsOneWidget);
      await tester.tap(find.text('Add'));
      expect(tapped, isTrue);
    });
  });

  group('App shell', () {
    testWidgets('shows four tabs and switches between them', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // Avoid opening a real database in a widget test.
            themeModeProvider.overrideWith((ref) => Stream.value(ThemeMode.light)),
          ],
          child: const ProjectBApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Timeline is the landing tab.
      expect(find.text('Nothing recorded yet'), findsOneWidget);
      for (final label in ['Timeline', 'Calendar', 'Weather', 'Settings']) {
        expect(find.text(label), findsWidgets);
      }

      await tester.tap(find.byIcon(Icons.calendar_month_outlined));
      await tester.pumpAndSettle();
      expect(find.text('No events yet'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Appearance'), findsOneWidget);
    });
  });
}
