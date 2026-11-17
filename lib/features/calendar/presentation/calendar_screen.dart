import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/db/app_database.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/content_width.dart';
import '../../../core/widgets/empty_state.dart';
import '../calendar_providers.dart';

/// S9 — month grid + selected day agenda (events). Timeline merge later.
class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  static const _weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(visibleCalendarMonthProvider);
    final selected = ref.watch(selectedCalendarDayProvider);
    final eventDays = ref.watch(eventDaysInMonthProvider).valueOrNull ?? {};
    final events = ref.watch(eventsForSelectedDayProvider).valueOrNull ?? [];
    final monthLabel = DateFormat.yMMMM().format(month);
    final dayLabel = DateFormat.MMMEd().format(selected);
    final timeFmt = DateFormat.Hm();

    final first = DateTime(month.year, month.month, 1);
    // Monday-based: weekday 1 = Mon … 7 = Sun
    final lead = first.weekday - 1;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final cells = lead + daysInMonth;
    final rows = (cells / 7).ceil();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(
            tooltip: 'Today',
            onPressed: () {
              final n = DateTime.now();
              final today = DateTime(n.year, n.month, n.day);
              ref.read(selectedCalendarDayProvider.notifier).state = today;
              ref.read(visibleCalendarMonthProvider.notifier).state =
                  DateTime(today.year, today.month);
            },
            icon: const Icon(Icons.today_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(Routes.eventNew),
        tooltip: 'New event',
        child: const Icon(Icons.add),
      ),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    final m = DateTime(month.year, month.month - 1);
                    ref.read(visibleCalendarMonthProvider.notifier).state = m;
                  },
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    monthLabel,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    final m = DateTime(month.year, month.month + 1);
                    ref.read(visibleCalendarMonthProvider.notifier).state = m;
                  },
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final w in _weekdays)
                  Expanded(
                    child: Center(
                      child: Text(
                        w,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            for (var r = 0; r < rows; r++)
              Row(
                children: [
                  for (var c = 0; c < 7; c++)
                    Expanded(
                      child: _DayCell(
                        index: r * 7 + c,
                        lead: lead,
                        daysInMonth: daysInMonth,
                        month: month,
                        selected: selected,
                        hasEvent: eventDays.contains(
                          r * 7 + c - lead + 1,
                        ),
                        onTap: (day) {
                          ref.read(selectedCalendarDayProvider.notifier).state =
                              day;
                        },
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 20),
            Text(
              dayLabel,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (events.isEmpty)
              const EmptyState(
                icon: Icons.event_outlined,
                title: 'No events',
                message: 'Tap + to add one for this day.',
              )
            else
              for (final e in events)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(
                      e.allDay ? Icons.calendar_today_outlined : Icons.event,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(e.title),
                    subtitle: Text(_eventSubtitle(e, timeFmt)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(Routes.eventEdit(e.id)),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  static String _eventSubtitle(CalendarEvent e, DateFormat timeFmt) {
    if (e.allDay) return 'All day';
    final s = DateTime.fromMillisecondsSinceEpoch(e.startAt, isUtc: true)
        .toLocal();
    final end =
        DateTime.fromMillisecondsSinceEpoch(e.endAt, isUtc: true).toLocal();
    return '${timeFmt.format(s)} – ${timeFmt.format(end)}';
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.index,
    required this.lead,
    required this.daysInMonth,
    required this.month,
    required this.selected,
    required this.hasEvent,
    required this.onTap,
  });

  final int index;
  final int lead;
  final int daysInMonth;
  final DateTime month;
  final DateTime selected;
  final bool hasEvent;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    final dayNum = index - lead + 1;
    if (dayNum < 1 || dayNum > daysInMonth) {
      return const SizedBox(height: 44);
    }
    final day = DateTime(month.year, month.month, dayNum);
    final isSelected = selected.year == day.year &&
        selected.month == day.month &&
        selected.day == day.day;
    final isToday = () {
      final n = DateTime.now();
      return n.year == day.year && n.month == day.month && n.day == day.day;
    }();

    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => onTap(day),
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 44,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? scheme.primary
                    : isToday
                        ? scheme.primaryContainer
                        : null,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$dayNum',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isSelected
                          ? scheme.onPrimary
                          : isToday
                              ? scheme.onPrimaryContainer
                              : null,
                      fontWeight: isSelected || isToday ? FontWeight.w600 : null,
                    ),
              ),
            ),
            if (hasEvent)
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: isSelected ? scheme.onPrimary : scheme.primary,
                  shape: BoxShape.circle,
                ),
              )
            else
              const SizedBox(height: 5),
          ],
        ),
      ),
    );
  }
}
