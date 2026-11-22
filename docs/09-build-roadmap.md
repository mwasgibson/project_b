# Build roadmap: what we actually did

How Project B was built in practice, not only how it was planned. Companion to [`08-security.md`](08-security.md) and [`10-code-health.md`](10-code-health.md).

**Audience:** you (and anyone revisiting the repo later).  
**This file is the only lived roadmap.**

---

## 1. North star and constraints

### Product intent (from docs 01–02)

- Privacy-first **location timeline + calendar** on one phone.
- Local SQLite is the source of truth; cloud is optional and encrypted (Phase 9).
- Battery and Samsung One UI reliability matter more than feature count early on.

### Hard constraints

| Constraint | Effect |
| --- | --- |
| **No physical iPhone** | Android-first tracking; iOS simulator for UI only; `LocationTracker` interface |
| **Personal / no revenue** | Free stack: Geolocator, OS geocoder, Open-Meteo |
| **Supabase only at Phase 9** | No auth, keys, or sync UI until then |
| **Display name “Project B”** | No underscore in user-facing name |
| **Device: Samsung SM-A176B** | FGS, battery tip, smoke tests aimed at aggressive OEM behaviour |

### Engineering rules (doc 06)

1. External capabilities behind interfaces.
2. Local-first before network.
3. Each phase runnable on the Samsung.
4. Soft rule: finish phase core before the next (calendar/weather may overlap tracking soak).

---

## 2. Planned vs actual

```text
Plan:   0 → 1 → 2 → 3 (risk) → 4 → 5 → 6/7 → 8 → MVP soak → 9 → 10
Actual: 0 → 1 → 2 → 3 core → 4 → 5 → 6 → 7 → 8 polish
Open:   3 harden, 9 sync, full GPS trip polylines, longer soak
```

---

## 3. Phase narrative (summary)

| Phase | Shipped |
| --- | --- |
| **0 Setup** | Flutter + FVM, docs, Project B name; iOS toolchain path fix |
| **1 Foundations** | Riverpod, go_router, Drift, theme, shell |
| **2 Permissions** | Onboarding, background disclosure flag, settings redirect |
| **3 Tracking** | Geolocator + FGS, modes, pause/stop, gaps, auto-saver |
| **4 Segmentation** | Visits/trips, timeline rail, merge same-place stays |
| **5 Places** | Platform geocoder, rename, unique places + history |
| **6 Calendar** | Movement log, events, reminders |
| **7 Weather** | Open-Meteo, cache, calendar day chip |
| **8 Data + polish** | Export/delete/retention, Trash (visits + places), maps, icon |

**Still open in Phase 3:** headless after swipe-kill, boot restart, formal multi-day battery log.

**Maps note:** Day map = visit pins; trip map = line between from/to visit centres (not full raw-point polylines yet).

---

## 4. Cross-cutting incidents

| Issue | Fix |
| --- | --- |
| Theme change reset navigation | Stable `GoRouter` + selective refresh |
| Permission loop on Start tracking | Disclosure flag + system settings |
| Rename crash under debugger | Stateful dialog owns `TextEditingController` |
| Same place many timeline rows | Merge overlap + proximity + same name |
| Docs dual `07` / `08` files | Single numbers: 07 decisions, 08 security, 09 roadmap, 10 code health |
| Launcher still Flutter logo | Adaptive icon + remove default mipmap PNGs; reinstall app |

---

## 5. Architecture

```text
LocationTracker  → raw_points (hidden from UI)
Segmenter        → visits / trips / gaps
PlaceResolver    → places → visit.place_id
UI               → repositories / session (not plugins)
```

---

## 6. Done vs not claimed

**Usable daily on Samsung:** track, segment, places, calendar, weather, export, trash, basic maps.

**Not claimed:** multi-day gap-free under OEM kill; measured battery week; full GPS polylines; Phase 9 sync.

---

## 7. Next

1. MVP soak.
2. Phase 3 hardening as issues appear.
3. Phase 9 encrypted sync when needed.
4. Optional richer trip polylines from raw points.
5. Phase 10 release prep only if distributing beyond personal use.

---

## 8. Decision log (short)

| Date | Decision |
| --- | --- |
| 2026-10 | Docs before code |
| 2026-11-10 | Project B name; no iPhone; Supabase @ Phase 9 |
| 2026-11-10 | Geolocator first (interface allows swap) |
| 2026-11-16 | FGS required on Android |
| 2026-11-19 | Points not user-facing; aggressive same-place merge |
| 2026-11-22 | Maps (OSM); Trash for places; docs numbers fixed |

*Last updated: 2026-11-22.*
