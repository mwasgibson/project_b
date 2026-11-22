# Implementation Plan: Project B

## Approach

Build order follows risk. The riskiest thing is reliable background tracking, proven early. Lived path and constraints: [`09-build-roadmap.md`](09-build-roadmap.md).

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
- [x] Raw samples on-device for segmentation only — **not shown in UI**
- [x] Soft-delete visits and places → Settings → **Trash** (tabs, select-all, restore / permanent)
- [x] Places list (S15): unique places, visit count, detail history
- [x] Same-place visit merge (overlap + proximity + same name; prefer real names over plus codes)
- [x] Gap rows when tracking was paused / off
- [x] Timeline left-rail design
- [x] Calendar weather chip (daily forecast for selected day)
- [x] Day map (visit pins) and trip map (start→end line) via OSM tiles
- [x] Adaptive app icon (teal `#0F766E`, pin + stem)

## Phase 7: Weather (F7)

- [x] `WeatherProvider` (Open-Meteo), coordinate rounding (~1 km), cache table
- [x] Weather screen S12; offline stale-data label
- [x] Weather chip on calendar day

## Visit & place rules (product)

1. **One continuous stay at one location = one visit** on the day timeline; pause/stop shows a **gap**, not a second place card.
2. **Places list** shows each location once; tap for visit dates/times and count.
3. Nearby duplicate place rows (~120 m) are consolidated; visits re-pointed.
4. Overlapping segmenter fragments and plus-code vs named labels merge (~300 m / same name).
5. Raw GPS points are not user-facing.

## Progress log

- 2026-11-17: Phase 6 calendar core.
- 2026-11-19: Calendar as movement log; Phase 7 weather; Phase 8 data control.
- 2026-11-19: Visit merge, places history, points hidden, Trash for visits.
- 2026-11-22: Calendar weather chip; day/trip maps; places in Trash; docs numbering cleaned (09 roadmap, 10 code health only).

## Next

1. MVP soak on device.
2. Phase 3 hardening (boot / swipe-kill / battery log) as needed.
3. Phase 9 encrypted sync when ready.
