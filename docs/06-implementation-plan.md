# Implementation Plan: Project B

## Approach
Build order follows risk. The riskiest thing is reliable background tracking, proven early. See [docs/07-build-roadmap.md](07-build-roadmap.md) for the lived path.

## Status

| Phase | Status |
| --- | --- |
| 0–5 Tracking, timeline, places | Core done |
| 6 Calendar as movement log + events/reminders | Core done |
| 7 Weather (Open-Meteo) | Core done |
| 8 Data control | Next |
| 9 Encrypted sync | After MVP soak |

## Phase 7: Weather (F7)
- [x] `WeatherProvider` (Open-Meteo), coordinate rounding (~1 km), cache table
- [x] Weather screen S12; offline stale-data label
- [ ] Weather chip on calendar day (optional polish)

## Progress log
- 2026-11-17: Phase 6 calendar core.
- 2026-11-19: Calendar patched as movement log (visits/trips primary). Phase 7 weather.
