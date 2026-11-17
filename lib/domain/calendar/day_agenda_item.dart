import '../../core/db/app_database.dart';

enum DayAgendaKind { event, visit }

/// One row on the calendar day agenda (events + timeline visits).
class DayAgendaItem {
  const DayAgendaItem.event(this.event)
      : kind = DayAgendaKind.event,
        visit = null;

  const DayAgendaItem.visit(this.visit)
      : kind = DayAgendaKind.visit,
        event = null;

  final DayAgendaKind kind;
  final CalendarEvent? event;
  final Visit? visit;

  int get sortAt => switch (kind) {
        DayAgendaKind.event => event!.startAt,
        DayAgendaKind.visit => visit!.startAt,
      };
}
