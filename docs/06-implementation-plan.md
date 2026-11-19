# Implementation Plan: Project B

## Approach
Build order follows risk. The riskiest thing is reliable background tracking, proven early. See progress log below for the lived path and constraints (Android-first, no iPhone hardware, Supabase deferred to Phase 9).

## Status

| Phase | Status |
| --- | --- |
| 0–5 Tracking, timeline, places | Core done |
| 6 Calendar as movement log + events/reminders | Core done |
| 7 Weather (Open-Meteo) | Core done |
| 8 Data control | Core done |
| 9 Encrypted sync | Deferred until after MVP soak |

## Phase 8: Data control (F8)
- [x] S17 Data and export — counts, JSON export, GPX export (share sheet)
- [x] Delete all local data with typed `DELETE` confirmation; stops tracking first
- [x] Raw point retention (default 30 days) on Tracking settings; purge on Data open / Find visits
- [x] Appearance already had light/dark/system
- [ ] Places list screen (S15) — optional polish, not blocking F8

## Phase 7: Weather (F7)
- [x] `WeatherProvider` (Open-Meteo), coordinate rounding (~1 km), cache table
- [x] Weather screen S12; offline stale-data label
- [ ] Weather chip on calendar day (optional polish)

## Progress log
- 2026-11-17: Phase 6 calendar core.
- 2026-11-19: Calendar patched as movement log (visits/trips primary). Phase 7 weather.
- 2026-11-19: Find visits feedback + relaxed manual thresholds; rename dialog dispose fix.
- 2026-11-19: Phase 8 data control (export JSON/GPX, delete all, retention).
