# Implementation Plan: Project B

## Approach

Build order follows risk. The riskiest thing is reliable background tracking, proven early. See progress log below for the lived path and constraints (Android-first, no iPhone hardware, Supabase deferred to Phase 9).

## Status

| Phase | Status |
| --- | --- |
| 0–5 Tracking, timeline, places | Core done |
| 6 Calendar as movement log + events/reminders | Core done |
| 7 Weather (Open-Meteo) | Core done |
| 8 Data control + polish | Core done |
| 9 Encrypted sync | Deferred until after MVP soak |

## Phase 8: Data control + polish (F8)

- [x] S17 Data and export — JSON / GPX, typed `DELETE`, retention
- [x] Tracking on/off (not only pause); settings under Settings → Tracking
- [x] Raw samples stay on-device for segmentation only — **not shown in UI**
- [x] Soft-delete visits → Settings → Deleted visits (restore / permanent)
- [x] Places list (S15): **unique places**, visit count, detail history (dates/times)
- [x] Same-place visit merge on timeline (overlap + proximity + same name; prefer real names over plus codes)
- [x] Gap rows when tracking was paused / off / no location
- [x] Timeline left-rail design (visits / trips / gaps)
- [ ] Day/trip maps (optional; needs tiles)
- [ ] Weather chip on calendar day (optional)

## Phase 7: Weather (F7)

- [x] `WeatherProvider` (Open-Meteo), coordinate rounding (~1 km), cache table
- [x] Weather screen S12; offline stale-data label
- [ ] Weather chip on calendar day (optional polish)

## Visit & place rules (product)

1. **One continuous stay at one location = one visit** on the day timeline, even if tracking paused/stopped in between (gap row explains the hole).
2. **Places list** shows each location once; tap for every visit date/time and count.
3. Nearby duplicate place records (~120 m) are consolidated; visits are re-pointed.
4. Overlapping segmenter fragments and plus-code vs named labels at the same spot are merged (~300 m / same name).
5. Raw GPS points are not a user-facing concept.

## Progress log

- 2026-11-17: Phase 6 calendar core.
- 2026-11-19: Calendar as movement log; Phase 7 weather; Phase 8 data control.
- 2026-11-19: Find visits feedback; rename dialog dispose fix; soft-delete trash.
- 2026-11-19: Hide points from UI; gap rows; timeline rail; places with history.
- 2026-11-19: Fix same-place timeline spam (merge overlaps + same name + consolidate).
