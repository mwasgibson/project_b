import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import '../../core/db/calendar_events_repository.dart';
import '../../core/db/reminders_repository.dart';
import '../../core/providers.dart';
import '../../domain/calendar/day_agenda_item.dart';
import '../tracking/tracking_providers.dart';
import 'data/notification_service.dart';

final calendarEventsRepositoryProvider = Provider<CalendarEventsRepository>(
  (ref) => CalendarEventsRepository(ref.watch(databaseProvider)),
);

final remindersRepositoryProvider = Provider<RemindersRepository>(
  (ref) => RemindersRepository(ref.watch(databaseProvider)),
);

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService();
  service.init();
  return service;
});

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

final visitsForSelectedDayProvider = StreamProvider<List<Visit>>((ref) {
  final day = ref.watch(selectedCalendarDayProvider);
  return ref.watch(segmentationRepositoryProvider).watchVisitsForDay(day);
});

/// Events + visits for the selected day, sorted by start time.
final dayAgendaProvider = Provider<AsyncValue<List<DayAgendaItem>>>((ref) {
  final events = ref.watch(eventsForSelectedDayProvider);
  final visits = ref.watch(visitsForSelectedDayProvider);
  if (events.isLoading || visits.isLoading) {
    return const AsyncValue.loading();
  }
  if (events.hasError) return AsyncValue.error(events.error!, StackTrace.current);
  if (visits.hasError) return AsyncValue.error(visits.error!, StackTrace.current);

  final items = <DayAgendaItem>[
    for (final e in events.valueOrNull ?? const <CalendarEvent>[])
      DayAgendaItem.event(e),
    for (final v in visits.valueOrNull ?? const <Visit>[])
      DayAgendaItem.visit(v),
  ]..sort((a, b) => a.sortAt.compareTo(b.sortAt));
  return AsyncValue.data(items);
});

final eventDaysInMonthProvider = StreamProvider<Set<int>>((ref) {
  final month = ref.watch(visibleCalendarMonthProvider);
  return ref
      .watch(calendarEventsRepositoryProvider)
      .watchEventDaysInMonth(month);
});

final reminderForEventProvider =
    FutureProvider.family<Reminder?, String>((ref, eventId) {
  return ref.watch(remindersRepositoryProvider).forEvent(eventId);
});

/// Schedule or cancel a reminder for an event. Returns false if permission denied.
Future<bool> applyEventReminder({
  required WidgetRef ref,
  required String eventId,
  required String eventTitle,
  required int eventStartAt,
  int? offsetBeforeMin,
}) async {
  final reminders = ref.read(remindersRepositoryProvider);
  final notifications = ref.read(notificationServiceProvider);

  final existing = await reminders.forEvent(eventId);
  if (existing?.notificationId != null) {
    await notifications.cancel(existing!.notificationId!);
  }

  if (offsetBeforeMin == null) {
    await reminders.cancelForEvent(eventId);
    return true;
  }

  final granted = await notifications.requestPermission();
  if (!granted) {
    await reminders.cancelForEvent(eventId);
    return false;
  }

  final fireAtMs =
      eventStartAt - offsetBeforeMin * 60 * 1000;
  final row = await reminders.upsertForEvent(
    eventId: eventId,
    fireAt: fireAtMs,
    offsetBeforeMin: offsetBeforeMin,
  );
  final notifId =
      row.notificationId ?? RemindersRepository.notificationIdFor(row.id);
  final fireLocal =
      DateTime.fromMillisecondsSinceEpoch(fireAtMs, isUtc: true).toLocal();
  await notifications.schedule(
    id: notifId,
    title: eventTitle,
    body: offsetBeforeMin == 0
        ? 'Starting now'
        : 'Starts in $offsetBeforeMin min',
    fireAtLocal: fireLocal,
  );
  return true;
}

Future<void> cancelEventReminder(WidgetRef ref, String eventId) async {
  final reminders = ref.read(remindersRepositoryProvider);
  final notifications = ref.read(notificationServiceProvider);
  final existing = await reminders.forEvent(eventId);
  if (existing?.notificationId != null) {
    await notifications.cancel(existing!.notificationId!);
  }
  await reminders.cancelForEvent(eventId);
}
