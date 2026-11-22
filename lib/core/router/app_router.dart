import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/calendar/presentation/calendar_screen.dart';
import '../../features/calendar/presentation/event_editor_screen.dart';
import '../../features/map/presentation/day_map_screen.dart';
import '../../features/map/presentation/trip_map_screen.dart';
import '../../features/onboarding/presentation/background_permission_screen.dart';
import '../../features/onboarding/presentation/location_permission_screen.dart';
import '../../features/onboarding/presentation/welcome_screen.dart';
import '../../features/settings/presentation/appearance_screen.dart';
import '../../features/settings/presentation/data_screen.dart';
import '../../features/settings/presentation/keep_alive_screen.dart';
import '../../features/settings/presentation/places_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/settings/presentation/tracking_settings_screen.dart';
import '../../features/settings/presentation/trash_screen.dart';
import '../../features/timeline/presentation/timeline_screen.dart';
import '../../features/weather/presentation/weather_screen.dart';
import '../permissions/permission_providers.dart';
import 'app_shell.dart';

abstract final class Routes {
  static const onboardingWelcome = '/onboarding/welcome';
  static const onboardingLocation = '/onboarding/location';
  static const onboardingBackground = '/onboarding/background';
  static const timeline = '/timeline';
  static const calendar = '/calendar';
  static const eventNew = '/calendar/event/new';
  static String eventEdit(String id) => '/calendar/event/$id';
  static String dayMap(DateTime day) {
    final y = day.year.toString().padLeft(4, '0');
    final m = day.month.toString().padLeft(2, '0');
    final d = day.day.toString().padLeft(2, '0');
    return '/map/day/$y-$m-$d';
  }

  static String tripMap(String id) => '/map/trip/$id';
  static const weather = '/weather';
  static const settings = '/settings';
  static const appearance = '/settings/appearance';
  static const trackingSettings = '/settings/tracking';
  static const data = '/settings/data';
  static const places = '/settings/places';
  static String placeDetail(String key) =>
      '/settings/places/${Uri.encodeComponent(key)}';
  static const trash = '/settings/trash';
  static const keepAlive = '/help/keep-alive';
}

class _RouterRefresh extends ChangeNotifier {
  void ping() => notifyListeners();
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh();
  ref.onDispose(refresh.dispose);

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
      GoRoute(
        path: Routes.eventNew,
        builder: (context, state) => const EventEditorScreen(),
      ),
      GoRoute(
        path: '/calendar/event/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          if (id == 'new') return const EventEditorScreen();
          return EventEditorScreen(eventId: id);
        },
      ),
      GoRoute(
        path: '/map/day/:date',
        builder: (context, state) {
          final raw = state.pathParameters['date']!;
          final parts = raw.split('-');
          final day = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
          return DayMapScreen(day: day);
        },
      ),
      GoRoute(
        path: '/map/trip/:id',
        builder: (context, state) {
          return TripMapScreen(tripId: state.pathParameters['id']!);
        },
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
                  GoRoute(
                    path: 'data',
                    builder: (context, state) => const DataScreen(),
                  ),
                  GoRoute(
                    path: 'places',
                    builder: (context, state) => const PlacesScreen(),
                    routes: [
                      GoRoute(
                        path: ':key',
                        builder: (context, state) {
                          final raw = state.pathParameters['key']!;
                          return PlaceDetailScreen(
                            placeKey: Uri.decodeComponent(raw),
                          );
                        },
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'trash',
                    builder: (context, state) => const TrashScreen(),
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
