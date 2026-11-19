import '../../core/db/app_database.dart';

enum DayAgendaKind { visit, trip, event }

/// One row on the calendar day log (timeline first, optional events).
class DayAgendaItem {
  const DayAgendaItem.visit(this.visit)
      : kind = DayAgendaKind.visit,
        trip = null,
        event = null;

  const DayAgendaItem.trip(this.trip)
      : kind = DayAgendaKind.trip,
        visit = null,
        event = null;

  const DayAgendaItem.event(this.event)
      : kind = DayAgendaKind.event,
        visit = null,
        trip = null;

  final DayAgendaKind kind;
  final Visit? visit;
  final Trip? trip;
  final CalendarEvent? event;

  int get sortAt => switch (kind) {
        DayAgendaKind.visit => visit!.startAt,
        DayAgendaKind.trip => trip!.startAt,
        DayAgendaKind.event => event!.startAt,
      };
}
