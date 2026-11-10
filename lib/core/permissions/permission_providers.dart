import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import '../settings/setting_keys.dart';
import 'permission_service.dart';

final permissionServiceProvider = Provider<PermissionService>(
  (ref) => PermissionService(),
);

/// Live snapshot; invalidate after any request so UI refreshes.
final locationPermissionProvider =
    FutureProvider<LocationPermissionSnapshot>((ref) async {
  final service = ref.watch(permissionServiceProvider);
  return service.snapshot();
});

final onboardingCompletedProvider = StreamProvider<bool>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.watch(SettingKeys.onboardingCompleted).map(
        (raw) => raw == 'true',
      );
});

Future<void> markOnboardingCompleted(WidgetRef ref) async {
  await ref
      .read(settingsRepositoryProvider)
      .write(SettingKeys.onboardingCompleted, 'true');
}
