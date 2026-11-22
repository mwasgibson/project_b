import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_b/app.dart';
import 'package:project_b/core/providers.dart';

void main() {
  testWidgets('App smoke test builds ProjectBApp', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          themeModeProvider.overrideWith((ref) => Stream.value(ThemeMode.light)),
        ],
        child: const ProjectBApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ProjectBApp), findsOneWidget);
  });
}
