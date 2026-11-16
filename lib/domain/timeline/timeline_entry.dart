import '../../core/db/app_database.dart';

/// One row on the day timeline (docs/03, S5).
enum TimelineEntryKind { visit, trip }

class TimelineEntry {
  const TimelineEntry.visit(this.visit)
      : kind = TimelineEntryKind.visit,
        trip = null;

  const TimelineEntry.trip(this.trip)
      : kind = TimelineEntryKind.trip,
        visit = null;

  final TimelineEntryKind kind;
  final Visit? visit;
  final Trip? trip;

  int get sortAt => switch (kind) {
        TimelineEntryKind.visit => visit!.startAt,
        TimelineEntryKind.trip => trip!.startAt,
      };
}
