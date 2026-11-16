import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/calendar/presentation/calendar_screen.dart';
import '../../features/onboarding/presentation/background_permission_screen.dart';
import '../../features/onboarding/presentation/location_permission_screen.dart';
import '../../features/onboarding/presentation/welcome_screen.dart';
import '../../features/settings/presentation/appearance_screen.dart';
import '../../features/settings/presentation/keep_alive_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/settings/presentation/tracking_settings_screen.dart';
import '../../features/timeline/presentation/timeline_screen.dart';
import '../../features/weather/presentation/weather_screen.dart';
import '../permissions/permission_providers.dart';
import 'app_shell.dart';

/// Route paths follow docs/03-app-flow.md.
abstract final class Routes {
  static const onboardingWelcome = '/onboarding/welcome';
  static const onboardingLocation = '/onboarding/location';
  static const onboardingBackground = '/onboarding/background';
  static const timeline = '/timeline';
  static const calendar = '/calendar';
  static const weather = '/weather';
  static const settings = '/settings';
  static const appearance = '/settings/appearance';
  static const trackingSettings = '/settings/tracking';
  static const keepAlive = '/help/keep-alive';
}

/// Notifier that bumps when onboarding completion changes so GoRouter
/// re-runs redirect without destroying the navigator stack.
class _RouterRefresh extends ChangeNotifier {
  void ping() => notifyListeners();
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh();
  ref.onDispose(refresh.dispose);

  // Only refresh when the *value* of onboarding completion changes.
  // Do not watch here — watching rebuilds this provider and creates a new
  // GoRouter, which resets the user to initialLocation (e.g. after theme).
  ref.listen<AsyncValue<bool>>(onboardingCompletedProvider, (prev, next) {
    final was = prev?.valueOrNull;
    final now = next.valueOrNull;
    if (was != now) refresh.ping();
  });

  return GoRouter(
    initialLocation: Routes.timeline,
    refreshListenable: refresh,
    redirect: (context, state) {
      final path = state.uri.path;
      final inOnboarding = path.startsWith('/onboarding');

      final onboarding = ref.read(onboardingCompletedProvider);
      if (onboarding.isLoading) return null;

      final completed = onboarding.valueOrNull ?? false;

      if (!completed && !inOnboarding) {
        return Routes.onboardingWelcome;
      }
      if (completed && path == Routes.onboardingWelcome) {
        return Routes.timeline;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.onboardingWelcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: Routes.onboardingLocation,
        builder: (context, state) => const LocationPermissionScreen(),
      ),
      GoRoute(
        path: Routes.onboardingBackground,
        builder: (context, state) => const BackgroundPermissionScreen(),
      ),
      GoRoute(
        path: Routes.keepAlive,
        builder: (context, state) => const KeepAliveScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.timeline,
                builder: (context, state) => const TimelineScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.calendar,
                builder: (context, state) => const CalendarScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.weather,
                builder: (context, state) => const WeatherScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.settings,
                builder: (context, state) => const SettingsScreen(),
                routes: [
                  GoRoute(
                    path: 'appearance',
                    builder: (context, state) => const AppearanceScreen(),
                  ),
                  GoRoute(
                    path: 'tracking',
                    builder: (context, state) => const TrackingSettingsScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
