# Todo

## Phase 0–3 — done (core)
Samsung smoke test OK. FGS notification, gaps, auto-saver, resume on start.

### Bugfix
- [x] Settings change (theme) no longer resets navigation (stable GoRouter)

## Phase 4: Segmentation (in progress)
- [x] Segmenter pure logic (100 m / 10 min) + unit tests
- [x] SegmentationRepository persists visits/trips, marks points processed
- [x] Timeline lists today's visits + refresh
- [ ] Tune thresholds against real Samsung data
- [ ] Trip rows on timeline
- [ ] Visit detail / edit (rename comes with Phase 5 labelling)
- [ ] Map preview (later)

## Still optional in Phase 3
- [ ] Swipe-from-recents headless engine
- [ ] Boot restart
- [ ] Multi-day battery log

## Next
Use the app for a day, tap refresh on Timeline, confirm visits look right; then place labels (Phase 5) or trip rows.
