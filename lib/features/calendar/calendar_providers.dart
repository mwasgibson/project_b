import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import '../../core/db/calendar_events_repository.dart';
import '../../core/providers.dart';

final calendarEventsRepositoryProvider = Provider<CalendarEventsRepository>(
  (ref) => CalendarEventsRepository(ref.watch(databaseProvider)),
);

final selectedCalendarDayProvider = StateProvider<DateTime>((ref) {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
});

final visibleCalendarMonthProvider = StateProvider<DateTime>((ref) {
  final n = DateTime.now();
  return DateTime(n.year, n.month);
});

final eventsForSelectedDayProvider =
    StreamProvider<List<CalendarEvent>>((ref) {
  final day = ref.watch(selectedCalendarDayProvider);
  return ref.watch(calendarEventsRepositoryProvider).watchForDay(day);
});

final eventDaysInMonthProvider = StreamProvider<Set<int>>((ref) {
  final month = ref.watch(visibleCalendarMonthProvider);
  return ref.watch(calendarEventsRepositoryProvider).watchEventDaysInMonth(month);
});
