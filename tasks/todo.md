# Todo

## Phase 0–4 — done (core)
Tracking, segmenter, timeline visits/trips, visit detail.

## Phase 5: Place labelling (in progress)
- [x] PlaceResolver interface + ResolvedPlace
- [x] PlatformPlaceResolver (OS geocoder via `geocoding`)
- [x] PlacesRepository + haversine radius match
- [x] PlaceLabelService (pending queue, label_state)
- [x] Timeline + detail show names; retry; auto-label toggle + disclosure
- [ ] User rename place (name_source = user)
- [ ] Optional offline city fallback

## Still optional
- [ ] Swipe-from-recents headless engine
- [ ] Boot restart
- [ ] Map preview
