import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/widgets/content_width.dart';
import '../calendar_providers.dart';
import '../data/ics_export.dart';

/// S11 — create or edit a calendar event (+ optional reminder).
class EventEditorScreen extends ConsumerStatefulWidget {
  const EventEditorScreen({super.key, this.eventId});

  final String? eventId;

  bool get isNew => eventId == null;

  @override
  ConsumerState<EventEditorScreen> createState() => _EventEditorScreenState();
}

class _EventEditorScreenState extends ConsumerState<EventEditorScreen> {
  final _title = TextEditingController();
  final _notes = TextEditingController();
  final _location = TextEditingController();

  late DateTime _start;
  late DateTime _end;
  bool _allDay = false;
  bool _loading = false;
  bool _hydrated = false;

  /// null = no reminder; otherwise minutes before start.
  int? _reminderOffsetMin;

  static const _reminderChoices = <(int?, String)>[
    (null, 'None'),
    (0, 'At start'),
    (5, '5 minutes before'),
    (15, '15 minutes before'),
    (30, '30 minutes before'),
    (60, '1 hour before'),
    (1440, '1 day before'),
  ];

  @override
  void initState() {
    super.initState();
    final day = ref.read(selectedCalendarDayProvider);
    _start = DateTime(day.year, day.month, day.day, 9);
    _end = _start.add(const Duration(hours: 1));
    if (!widget.isNew) {
      _load();
    } else {
      _hydrated = true;
    }
  }

  Future<void> _load() async {
    final e = await ref
        .read(calendarEventsRepositoryProvider)
        .getById(widget.eventId!);
    if (e == null || !mounted) {
      setState(() => _hydrated = true);
      return;
    }
    _title.text = e.title;
    _notes.text = e.notes ?? '';
    _location.text = e.locationText ?? '';
    _allDay = e.allDay;
    _start =
        DateTime.fromMillisecondsSinceEpoch(e.startAt, isUtc: true).toLocal();
    _end = DateTime.fromMillisecondsSinceEpoch(e.endAt, isUtc: true).toLocal();
    final reminder =
        await ref.read(remindersRepositoryProvider).forEvent(e.id);
    _reminderOffsetMin = reminder?.offsetBeforeMin;
    setState(() => _hydrated = true);
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _pickStart() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    if (_allDay) {
      setState(() {
        _start = DateTime(date.year, date.month, date.day);
        _end = _start.add(const Duration(days: 1));
      });
      return;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_start),
    );
    if (time == null || !mounted) return;
    setState(() {
      _start =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
      if (!_end.isAfter(_start)) {
        _end = _start.add(const Duration(hours: 1));
      }
    });
  }

  Future<void> _pickEnd() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _end,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    if (_allDay) {
      setState(() {
        _end = DateTime(date.year, date.month, date.day)
            .add(const Duration(days: 1));
      });
      return;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_end),
    );
    if (time == null || !mounted) return;
    setState(() {
      _end = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a title')),
      );
      return;
    }
    if (!_end.isAfter(_start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End must be after start')),
      );
      return;
    }

    setState(() => _loading = true);
    final offset = DateTime.now().timeZoneOffset.inMinutes;
    final startMs = _start.toUtc().millisecondsSinceEpoch;
    final endMs = _end.toUtc().millisecondsSinceEpoch;
    final repo = ref.read(calendarEventsRepositoryProvider);

    try {
      final String eventId;
      if (widget.isNew) {
        final created = await repo.create(
          title: title,
          startAt: startMs,
          endAt: endMs,
          utcOffsetMin: offset,
          allDay: _allDay,
          notes: _notes.text,
          locationText: _location.text,
        );
        eventId = created.id;
      } else {
        eventId = widget.eventId!;
        await repo.update(
          id: eventId,
          title: title,
          startAt: startMs,
          endAt: endMs,
          utcOffsetMin: offset,
          allDay: _allDay,
          notes: _notes.text,
          locationText: _location.text,
        );
      }

      final ok = await applyEventReminder(
        ref: ref,
        eventId: eventId,
        eventTitle: title,
        eventStartAt: startMs,
        offsetBeforeMin: _reminderOffsetMin,
      );
      if (!ok && mounted && _reminderOffsetMin != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Event saved, but notification permission was denied. '
              'Enable notifications in system settings for reminders.',
            ),
          ),
        );
      }
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete event?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || widget.eventId == null) return;
    await cancelEventReminder(ref, widget.eventId!);
    await ref
        .read(calendarEventsRepositoryProvider)
        .softDelete(widget.eventId!);
    if (mounted) context.pop();
  }

  Future<void> _exportIcs() async {
    if (widget.eventId == null) return;
    final e = await ref
        .read(calendarEventsRepositoryProvider)
        .getById(widget.eventId!);
    if (e == null) return;
    final ics = IcsExport.event(e);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${e.id}.ics');
    await file.writeAsString(ics);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/calendar')],
      subject: e.title,
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat.yMMMd().add_jm();
    final dayFmt = DateFormat.yMMMd();

    if (!_hydrated) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNew ? 'New event' : 'Edit event'),
        actions: [
          if (!widget.isNew) ...[
            IconButton(
              tooltip: 'Export .ics',
              onPressed: _loading ? null : _exportIcs,
              icon: const Icon(Icons.ios_share_outlined),
            ),
            IconButton(
              tooltip: 'Delete',
              onPressed: _loading ? null : _delete,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
          TextButton(
            onPressed: _loading ? null : _save,
            child: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('All day'),
              value: _allDay,
              onChanged: (v) {
                setState(() {
                  _allDay = v;
                  if (v) {
                    _start = DateTime(_start.year, _start.month, _start.day);
                    _end = _start.add(const Duration(days: 1));
                  }
                });
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Starts'),
              subtitle:
                  Text(_allDay ? dayFmt.format(_start) : fmt.format(_start)),
              trailing: const Icon(Icons.schedule),
              onTap: _pickStart,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Ends'),
              subtitle: Text(
                _allDay
                    ? dayFmt.format(_end.subtract(const Duration(days: 1)))
                    : fmt.format(_end),
              ),
              trailing: const Icon(Icons.schedule),
              onTap: _pickEnd,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int?>(
              initialValue: _reminderOffsetMin,
              decoration: const InputDecoration(
                labelText: 'Reminder',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final (value, label) in _reminderChoices)
                  DropdownMenuItem(value: value, child: Text(label)),
              ],
              onChanged: (v) => setState(() => _reminderOffsetMin = v),
            ),
            const SizedBox(height: 4),
            Text(
              'Reminders use a local notification on this phone. '
              'Nothing is sent to a server.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _location,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Location (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notes,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
