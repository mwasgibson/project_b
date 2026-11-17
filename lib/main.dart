import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'features/calendar/data/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Init notification plugin early so scheduled reminders can fire.
  await NotificationService().init();
  runApp(const ProviderScope(child: ProjectBApp()));
}
