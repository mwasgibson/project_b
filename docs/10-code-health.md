# Code health snapshot

**Date:** 2026-11-22  
Skills: code-quality, design.

## Score (MVP)

| Area | Score | Notes |
| --- | --- | --- |
| Architecture | 8/10 | Feature-first; tracker / place / weather interfaces |
| Privacy | 9/10 | Local SQLite; points hidden; export / delete / retention |
| UI consistency | 8/10 | Theme tokens; timeline rail; Trash |
| Tests | 4/10 | Segmenter / place-match unit tests mainly |
| Background reliability | 6/10 | FGS OK; OEM kill unproven long-term |

## Recent quality work

- Same-place visit merge; place consolidate
- Dead `points_screen` removed
- Trash multi-select for visits and places
- Adaptive launcher icon (vector); Flutter default mipmaps removed
- Docs: single numbering scheme (no stub dual files)

## Debt (non-blocking)

1. `todaysTimelineProvider` side-effect segmentation → dedicated job later.
2. Soft `catch` on weather/battery — intentional.
3. Trip maps are endpoints only, not full polylines.
4. Expand tests for `mergeNearbyVisits` and place consolidate.
5. Phase 9 sync not started.
