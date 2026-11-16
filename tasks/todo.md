# Todo

## Phase 0–3 — done (core)
Samsung smoke test OK. FGS notification, gaps, auto-saver, resume on start.

### Bugfix
- [x] Settings change (theme) no longer resets navigation (stable GoRouter)

## Phase 4: Segmentation (in progress)
- [x] Segmenter pure logic (100 m / 10 min) + unit tests
- [x] SegmentationRepository persists visits/trips, marks points processed
- [x] Timeline lists today's visits + refresh
- [x] Trip rows interleaved on timeline
- [x] Visit detail sheet (times, coords, delete)
- [ ] Tune thresholds against real Samsung data
- [ ] Map preview (optional later)

## Phase 5 next
- Place labelling (geocoder) → real names instead of "Unknown place"

## Still optional in Phase 3
- [ ] Swipe-from-recents headless engine
- [ ] Boot restart
- [ ] Multi-day battery log
