# Implementation Plan: Project B

## Approach
Build order follows risk. The riskiest thing in this app is **reliable background tracking on real phones** (Samsung especially, then iOS), so it gets proven early, before polish or sync. Everything else (UI, calendar, weather, sync) is well-understood and comes after.

Rules for the build:
1. Keep every external dependency behind an interface: `LocationTracker`, `PlaceResolver`, `WeatherProvider`, `SyncBackend`.
2. Local-first: every feature must work with no account and no internet before it touches the cloud.
3. Each phase ends with something you can run on your phone.
4. No deadline, so finish a phase properly before starting the next.

Tracking feature IDs refer to doc 01 (F1 to F9). Screen IDs refer to doc 03.

**Lived path, constraints, and divergences from this plan:** see [docs/07-build-roadmap.md](07-build-roadmap.md).

## Phases

### Phase 0–5
Core complete. See docs/07 and the progress log below.

### Phase 6: Calendar and reminders (F6)
Goal: a calendar that also shows your movements.
Tasks:
- [x] Month (S9) and day agenda merging events and timeline visits.
- [x] Event editor S11 with validation.
- [x] Local notifications; permission on first reminder; cancel on delete.
- [x] `.ics` export (single event and selected day).
Done when: a reminder fires on-device after the app is backgrounded; day agenda shows both events and visits.
**Status:** Core done 2026-11-17. Reboot reschedule of all reminders still optional hardening.

### Phase 7: Weather (F7)
Goal: forecast on the calendar.
Tasks:
- [ ] `WeatherProvider` (Open-Meteo), coordinate rounding, cache table.
- [ ] Weather screen S12; weather chip on S10 and event editor.
- [ ] Offline stale-data label.

### Phase 8: Data control and settings polish (F8)
- [ ] Retention, export JSON/GPX, delete-all, units, accessibility.

### MVP checkpoint
Use the app daily for 1 to 2 weeks before building sync.

### Phase 9: Encrypted cloud sync (F9)
Deferred until MVP checkpoint. Supabase only here.

### Phase 10: Hardening and release prep
Store packaging when/if distributing beyond personal use.

## Progress log
- 2026-10-22: Planning docs 00 to 06 created.
- 2026-11-10: Phases 0–2; Android-first; Project B name; Supabase at Phase 9.
- 2026-11-16: Phases 3–5 core (tracking, segmenter, places).
- 2026-11-17: docs/07-build-roadmap.md; Phase 6 calendar core (agenda, reminders, ICS).
