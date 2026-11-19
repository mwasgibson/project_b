import '../../core/db/app_database.dart';

/// One row on the day timeline (docs/03, S5).
enum TimelineEntryKind { visit, trip, gap }

class TimelineEntry {
  const TimelineEntry.visit(this.visit)
      : kind = TimelineEntryKind.visit,
        trip = null,
        gap = null;

  const TimelineEntry.trip(this.trip)
      : kind = TimelineEntryKind.trip,
        visit = null,
        gap = null;

  const TimelineEntry.gap(this.gap)
      : kind = TimelineEntryKind.gap,
        visit = null,
        trip = null;

  final TimelineEntryKind kind;
  final Visit? visit;
  final Trip? trip;
  final Gap? gap;

  int get sortAt => switch (kind) {
        TimelineEntryKind.visit => visit!.startAt,
        TimelineEntryKind.trip => trip!.startAt,
        TimelineEntryKind.gap => gap!.startAt,
      };
}
