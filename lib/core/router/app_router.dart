import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/calendar/presentation/calendar_screen.dart';
import '../../features/onboarding/presentation/background_permission_screen.dart';
import '../../features/onboarding/presentation/location_permission_screen.dart';
import '../../features/onboarding/presentation/welcome_screen.dart';
import '../../features/settings/presentation/appearance_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
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
}

final routerProvider = Provider<GoRouter>((ref) {
  final onboarding = ref.watch(onboardingCompletedProvider);

  return GoRouter(
    initialLocation: Routes.timeline,
    redirect: (context, state) {
      final path = state.uri.path;
      final inOnboarding = path.startsWith('/onboarding');

      // Still loading settings — do not redirect yet.
      if (onboarding.isLoading) return null;

      final completed = onboarding.value ?? false;

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
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
