import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'data_control_service.dart';

final dataControlServiceProvider = Provider<DataControlService>((ref) {
  return DataControlService(
    db: ref.watch(databaseProvider),
    settings: ref.watch(settingsRepositoryProvider),
  );
});
