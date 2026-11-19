import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Bottom tab bar: Timeline, Calendar, Weather, Settings (docs/03).
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: shell,
      bottomNavigationBar: Material(
        color: theme.colorScheme.surfaceContainerLowest,
        elevation: 0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Divider(
              height: 1,
              thickness: 1,
              color: theme.colorScheme.outlineVariant,
            ),
            NavigationBar(
              selectedIndex: shell.currentIndex,
              onDestinationSelected: (index) => shell.goBranch(
                index,
                initialLocation: index == shell.currentIndex,
              ),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.timeline_outlined),
                  selectedIcon: Icon(Icons.timeline),
                  label: 'Timeline',
                ),
                NavigationDestination(
                  icon: Icon(Icons.calendar_month_outlined),
                  selectedIcon: Icon(Icons.calendar_month),
                  label: 'Calendar',
                ),
                NavigationDestination(
                  icon: Icon(Icons.wb_cloudy_outlined),
                  selectedIcon: Icon(Icons.wb_cloudy),
                  label: 'Weather',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
