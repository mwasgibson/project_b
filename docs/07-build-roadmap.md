# Build roadmap — Project B

Lived path, constraints, and reasoning while building the app (not the original ideal plan alone).

## Constraints we worked under

| Constraint | Effect |
| --- | --- |
| Android-first (Samsung); no iPhone hardware | Background location, battery tip, and smoke tests on Android; iOS paths compile but are untested on device |
| Name stays **Project B** (no underscore) | Display strings and package branding |
| Supabase / encrypted sync | Explicitly deferred to **Phase 9** after local MVP |
| Privacy-first, local SQLite | No cloud identity; export/delete on device |

## Phases delivered (summary)

0. Scaffold, theme, router, Drift schema  
1. Onboarding + permissions (foreground → background disclosure)  
2–3. Tracking engine (Geolocator), modes, gaps, auto-saver  
4. Visit/trip segmentation  
5. Place labelling (platform geocoder) + user rename  
6. Calendar as movement log + local events/reminders  
7. Weather via Open-Meteo  
8. Data control (export, retention, delete all) + UX polish  

## Important product decisions

- **Timeline is the story of places**, not raw GPS. Points still record for segmentation but are hidden from Settings and Timeline.
- **Same place, one row:** overlapping or nearby visits (and same place name) merge into a single stay. Pause/stop creates a **gap** row, not a second place card.
- **Places screen:** unique locations with visit count; detail lists every visit’s date and time.
- **Soft delete** for visits with restore / permanent delete in trash.
- **Tracking:** full on/off plus pause; primary controls live under Settings → Tracking.

## Known limits

- Perfect “zero samples while stationary” is impossible; OS GPS still wakes — we only dedupe near-duplicates.
- Day/trip **maps** not built yet (tiles + polylines).
- Phase 9 sync not started.
- iOS real-device behaviour unverified.

## 2026-11-19 polish notes

User reported Timeline listing “Kwa Good Neighbour” many times for one stay (plus a plus-code fragment). Cause: merge required non-overlapping times (`gap >= 0`) and did not treat same place **name** as identity. Fix: merge on overlap, ~300 m proximity, same `placeId` or same name; consolidate place rows; re-merge after labelling.
