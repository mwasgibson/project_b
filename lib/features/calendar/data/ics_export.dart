import '../../../core/db/app_database.dart';

/// Minimal iCalendar (RFC 5545) builder for export.
class IcsExport {
  const IcsExport._();

  static String escape(String value) {
    return value
        .replaceAll('\\', '\\\\')
        .replaceAll(';', '\\;')
        .replaceAll(',', '\\,')
        .replaceAll('\n', '\\n');
  }

  static String formatUtc(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}${two(d.month)}${two(d.day)}T'
        '${two(d.hour)}${two(d.minute)}${two(d.second)}Z';
  }

  static String event(CalendarEvent e) {
    final buf = StringBuffer()
      ..writeln('BEGIN:VCALENDAR')
      ..writeln('VERSION:2.0')
      ..writeln('PRODID:-//Project B//EN')
      ..writeln('CALSCALE:GREGORIAN')
      ..writeln('BEGIN:VEVENT')
      ..writeln('UID:${e.id}@projectb.local')
      ..writeln('DTSTAMP:${formatUtc(DateTime.now().toUtc().millisecondsSinceEpoch)}');
    if (e.allDay) {
      final start = DateTime.fromMillisecondsSinceEpoch(e.startAt, isUtc: true);
      final end = DateTime.fromMillisecondsSinceEpoch(e.endAt, isUtc: true);
      String day(DateTime d) =>
          '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';
      buf.writeln('DTSTART;VALUE=DATE:${day(start)}');
      buf.writeln('DTEND;VALUE=DATE:${day(end)}');
    } else {
      buf.writeln('DTSTART:${formatUtc(e.startAt)}');
      buf.writeln('DTEND:${formatUtc(e.endAt)}');
    }
    buf.writeln('SUMMARY:${escape(e.title)}');
    if (e.locationText != null && e.locationText!.isNotEmpty) {
      buf.writeln('LOCATION:${escape(e.locationText!)}');
    }
    if (e.notes != null && e.notes!.isNotEmpty) {
      buf.writeln('DESCRIPTION:${escape(e.notes!)}');
    }
    buf
      ..writeln('END:VEVENT')
      ..writeln('END:VCALENDAR');
    return buf.toString();
  }

  static String events(List<CalendarEvent> list) {
    if (list.length == 1) return event(list.first);
    final buf = StringBuffer()
      ..writeln('BEGIN:VCALENDAR')
      ..writeln('VERSION:2.0')
      ..writeln('PRODID:-//Project B//EN')
      ..writeln('CALSCALE:GREGORIAN');
    for (final e in list) {
      buf
        ..writeln('BEGIN:VEVENT')
        ..writeln('UID:${e.id}@projectb.local')
        ..writeln(
          'DTSTAMP:${formatUtc(DateTime.now().toUtc().millisecondsSinceEpoch)}',
        );
      if (e.allDay) {
        final start =
            DateTime.fromMillisecondsSinceEpoch(e.startAt, isUtc: true);
        final end = DateTime.fromMillisecondsSinceEpoch(e.endAt, isUtc: true);
        String day(DateTime d) =>
            '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';
        buf.writeln('DTSTART;VALUE=DATE:${day(start)}');
        buf.writeln('DTEND;VALUE=DATE:${day(end)}');
      } else {
        buf.writeln('DTSTART:${formatUtc(e.startAt)}');
        buf.writeln('DTEND:${formatUtc(e.endAt)}');
      }
      buf.writeln('SUMMARY:${escape(e.title)}');
      if (e.locationText != null && e.locationText!.isNotEmpty) {
        buf.writeln('LOCATION:${escape(e.locationText!)}');
      }
      if (e.notes != null && e.notes!.isNotEmpty) {
        buf.writeln('DESCRIPTION:${escape(e.notes!)}');
      }
      buf.writeln('END:VEVENT');
    }
    buf.writeln('END:VCALENDAR');
    return buf.toString();
  }
}
