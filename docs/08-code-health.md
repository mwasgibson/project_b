# Code health snapshot (2026-11-19)

Skills used: **code-quality**, **design** (icon + brief alignment).

## Score (MVP)

| Area | Score | Notes |
| --- | --- | --- |
| Architecture | 8/10 | Feature-first; domain interfaces (tracker, place resolver, weather) |
| Privacy surface | 9/10 | Local SQLite; points hidden from UI; retention + delete all |
| UI consistency | 8/10 | Theme tokens + domain colours; timeline rail |
| Test coverage | 4/10 | Segmenter / place-match unit tests only |
| Background reliability | 6/10 | FGS on Android; OEM kill still a gap |
| Dead code | 9/10 | Removed `points_screen` after points left the UI |

## Fixed this pass

- App icon: adaptive Android (teal `#0F766E`, white pin + timeline)
- Deleted dead `lib/features/settings/presentation/points_screen.dart` (referenced removed providers)
- Same-place visit merge (prior commit: overlap + name + proximity)

## Remaining debt (non-blocking)

1. `todaysTimelineProvider` runs segmentation as a side effect of watching — prefer a dedicated bootstrap / job later.
2. Soft `catch (_)` in weather / battery paths — intentional; debug logging only if needed.
3. No map screens yet (tiles + polylines).
4. Phase 9 sync not started.
5. Expand unit tests for `mergeNearbyVisits` and place consolidate.

## Icon

Brand primary `#0F766E` from design brief. Android 8+ uses adaptive icon (`mipmap-anydpi-v26` + vector foreground). Reinstall the app (or clear launcher cache) to see the new icon.
