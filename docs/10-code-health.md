# Code health snapshot (2026-11-22)

Skills used: **code-quality**, **design**.

## Score (MVP)

| Area | Score | Notes |
| --- | --- | --- |
| Architecture | 8/10 | Feature-first; domain interfaces (tracker, place resolver, weather) |
| Privacy surface | 9/10 | Local SQLite; points hidden from UI; retention + delete all |
| UI consistency | 8/10 | Theme tokens + domain colours; timeline rail |
| Test coverage | 4/10 | Segmenter / place-match unit tests only |
| Background reliability | 6/10 | FGS on Android; OEM kill still a gap |
| Dead code | 9/10 | Points screen removed |

## Recent fixes

- Same-place visit merge; places history; Trash (visits + places)
- Calendar weather chip; day/trip OSM maps
- Adaptive launcher icon (teal pin); fallback mipmaps still need a clean rebuild/reinstall if the Flutter logo appears

## Remaining debt

1. Timeline provider side-effect segmentation → dedicated job later.
2. Trip maps are start→end lines, not full GPS polylines.
3. Phase 9 sync not started.
4. More unit tests for merge / place consolidate.

Canonical filename: **`docs/10-code-health.md`** (not `08-…`).
