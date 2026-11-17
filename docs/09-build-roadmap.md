# Build roadmap: what we actually did

This document records **how Project B was built in practice**, not only how it was planned. It sits beside `docs/08-security.md`. Where plan and path diverged, the reason is written down so future phases stay honest about constraints.

**Audience:** you (and anyone revisiting the repo months later).  
**Scope:** Phases 0–5 on `main` as of 2026-11-16, plus the decisions that shaped them.

---

## 1. North star and constraints

### Product intent (from docs 01–02)

- Privacy-first **location timeline + calendar** on one phone.
- Local SQLite is the source of truth; cloud is optional and encrypted (Phase 9).
- Battery and Samsung One UI reliability matter more than feature count early on.

### Hard constraints we treated as fixed

| Constraint | Effect on the build |
| --- | --- |
| **No physical iPhone** | Android-first for tracking. iOS simulator for UI only. `LocationTracker` stays an interface so iOS can land later without rewriting the UI. |
| **Personal / no revenue** | Prefer free stack: Geolocator, OS geocoder, Open-Meteo later. Paid Transistorsoft left as a *possible* swap behind the same interface, not a day-one dependency. |
| **Supabase only at Phase 9** | Explicit user decision. No premature auth, keys, or sync UI. |
| **Display name “Project B”** | Underscore removed from user-facing name; package/repo naming left stable. |
| **Real device is Samsung SM-A176B** | Keep-alive guide (S22), FGS notification, and battery tips targeted at Samsung’s aggressive optimisation. |

### Engineering rules (from doc 06, kept in force)

1. External capabilities behind interfaces: `LocationTracker`, `PlaceResolver`, (later) `WeatherProvider`, `SyncBackend`.
2. Local-first: feature works offline before any network.
3. Each phase ends with something runnable on the Samsung.
4. Finish a phase’s core before starting the next (soft rule — calendar/weather may run while tracking soaks).

---

## 2. Planned vs actual sequence

```text
Plan:   0 → 1 → 2 → 3 (risk) → 4 → 5 → 6/7 → 8 → MVP soak → 9 → 10
Actual: 0 → 1 → 2 → 3 core → 4 core → 5 core  |  still open: 3 harden, 6, 7, 8, 9…
```

We followed the **risk-first** order: permissions and tracking before polish. We did **not** wait for a multi-day battery log or swipe-kill survival before segmentation and labelling, because:

- You already had outdoor smoke tests and rising point counts on the Samsung.
- Readable visits/names make daily use more valuable *while* hardening continues.
- Doc 06 itself allows calendar/weather in parallel with tracking soak time.

What we deferred deliberately:

| Item | Why deferred |
| --- | --- |
| Transistorsoft / paid plugin | Free Geolocator + FGS is enough for personal Android; interface allows swap. |
| Boot restart + headless after swipe-kill | Hardening; needs more device time; not blocking a useful timeline. |
| Full day map (S6) / trip detail map (S8) | List timeline first; map is enhancement. |
| Places list (S15) | Rename from visit detail covers the main loop. |
| Offline city geocoder pack | Platform geocoder + user rename sufficient for v1 labelling. |
| Privacy policy draft | Needed again for Phase 10 / stores. |
| Supabase project | Phase 9 only. |

---

## 3. Phase-by-phase narrative

### Phase 0 — Setup

**Goal:** Clean repo, docs, app runs on Samsung and iOS simulator.

**What we did:** Flutter + FVM, docs 01–06, CI baseline, display name Project B.

**Friction:** iOS simulator failed with `objective_c` / `xcrun --show-sdk-path` because Xcode lived under Downloads. Fixed with `xcode-select` and license acceptance — not an app bug.

**Reasoning:** Prove the toolchain on *your* machines before any domain code. Simulator is enough without an iPhone.

---

### Phase 1 — Foundations

**Goal:** Shell, theme, Drift schema, settings.

**What we did:** Feature folders, Riverpod, go_router four tabs, light/dark/system, Drift tables mirroring doc 05, reusable empty states and chips.

**Reasoning:** Schema-first avoids rewriting storage when tracking lands. Theme tokens (doc 04) early so UI doesn’t fight redesign later.

---

### Phase 2 — Onboarding and permissions (F1)

**Goal:** Honest permission flow.

**What we did:** S1–S3, `PermissionService`, Android manifest / iOS plist strings, Timeline cards for denied / services-off / “Allow all the time”.

**Bug and fix:** After S3, “Start tracking” **re-looped** the disclosure. Cause: we re-requested background without remembering that disclosure had been shown, and permanent deny needed settings not another prompt. Fix: `background_disclosure_shown` setting + open system settings when permanently denied.

**Reasoning:** Wrong permission UX destroys trust and Play Store narrative later. Foreground first, background only when enabling tracking matches platform policy and doc 03.

---

### Phase 3 — Tracking engine (F2, F3)

**Goal:** Points on disk with the app backgrounded.

**Plan said:** Transistorsoft in debug, free alternative head-to-head, multi-day battery log.

**What we actually shipped:**

- `LocationTracker` interface + `GeolocatorLocationTracker` (free).
- `raw_points` writes with mode, accuracy, battery %.
- Android **foreground service notification** via Geolocator `ForegroundNotificationConfig` + wake lock.
- Modes high / balanced / saver (distance + interval).
- `TrackingSession`: pause/resume/stop, **resume on app start** if `tracking_enabled`, **gaps**, **auto-saver**, health / 30‑min stale banner.
- S14 tracking settings + S22 Samsung keep-alive guide.

**Smoke test (2026-11-16):** Outdoor / near-home on SM-A176B; logs showed FGS bind and position updates. Limited by Wi‑Fi range that day — not a full multi-day soak.

**Reasoning for Geolocator first:**

- Personal project; avoid paid licence until proven need.
- Interface means a paid plugin is a *replacement*, not a rewrite.
- FGS notification is the main lever against One UI killing the process when the app is only backgrounded (not swipe-killed).

**Still open in Phase 3:** swipe-from-recents headless, boot receiver, formal multi-day battery log, threshold tuning from long trails.

---

### Phase 4 — Segmentation and timeline (F4)

**Goal:** Points → visits and trips.

**What we shipped:**

- Pure `Segmenter` (100 m / ≥10 min) + unit tests.
- `SegmentationRepository`: visits, trips, mark points processed.
- Timeline: interleaved visit/trip rows, refresh, soft-delete visit.
- Visit detail sheet (times, coords, duration).

**Deferred:** full S6 map day view, merge visits, trip map polyline.

**Reasoning:** List UI unblocks daily reading without map tiles, keys, or tile-policy decisions. Thresholds match doc 02 defaults; tune only after you have *your* multi-day data.

---

### Phase 5 — Place labelling (F5)

**Goal:** Names, not coordinates.

**What we shipped:**

- `PlaceResolver` + `ResolvedPlace` / failure modes.
- `PlatformPlaceResolver` (`geocoding` → OS Geocoder / CLGeocoder).
- Haversine **place match** within radius; `PlacesRepository`.
- `PlaceLabelService` queue (`pending` → `done` / `failed` / `disabled`).
- Auto-label toggle with **privacy disclosure** (OS may contact vendor).
- User **rename** → `name_source = user`, `userEdited` so auto-label does not overwrite.

**Deferred:** S15 places list, offline GeoNames/S2 pack.

**Reasoning:** Platform geocoder is free and street-capable when online; local radius match avoids repeat network calls for Home/Work. Interface leaves room for offline or paid quality later. Disclosure matches doc 02 non-functional privacy rules.

---

## 4. Cross-cutting incidents (worth remembering)

| Issue | Root cause | Fix |
| --- | --- | --- |
| Theme change kicked user to Timeline | `routerProvider` **watched** onboarding stream; any `app_settings` write rebuilt `GoRouter` | Stable router + `refreshListenable` only when onboarding *value* changes |
| Permission loop on Start tracking | Re-prompting background after disclosure | Persist disclosure shown; deep-link to system settings when permanent |
| Provider dispose cast | Wrong dispose wiring on tracker | `ref.onDispose(tracker.dispose)` without invalid cast |

---

## 5. Architecture that stayed true

```text
LocationTracker  → raw_points
Segmenter        → visits / trips / gaps
PlaceResolver    → places → visit.place_id + label_state
UI               → repositories / session only (not plugins)
```

**Why this shape:** Doc 02’s “behind an interface” rule. Tracking and geocoding are the two dependencies most likely to be replaced (licence, quality, offline). UI and Drift should not care.

---

## 6. What “done” means for 0–5

**Core done (usable daily on Samsung):**

- Grant / deny paths, background disclosure.
- Track with notification; pause/resume; modes; auto-saver; gaps; resume after app restart.
- Segment into visits/trips; see them on Timeline; delete; rename places; auto-label with opt-out.

**Not claiming yet:**

- Multi-day gap-free trail under One UI with swipe-kill and reboot.
- Battery &lt;5% extra measured over a week.
- Map day view, calendar, weather, export, sync.

---

## 7. Next per implementation plan (doc 06)

Recommended order from here:

1. **Phase 6 — Calendar + reminders** (does not depend on tracking soak).
2. **Phase 7 — Weather** (Open-Meteo, rounded coords).
3. **Phase 3 hardening** in parallel on-device (boot, swipe-kill if needed, battery log).
4. **Phase 8 — Export / retention / polish.**
5. **MVP checkpoint** — 1–2 weeks real use.
6. **Phase 9 — Encrypted sync** (Supabase).
7. **Phase 10 — Release prep** only if distributing beyond personal use.

---

## 8. Decision log (short)

| Date | Decision | Reason |
| --- | --- | --- |
| 2026-10 | Docs before code | Align product, privacy, schema |
| 2026-11-10 | Name = Project B; no iPhone; Supabase @9 | User constraints |
| 2026-11-10 | Geolocator not Transistorsoft first | Free personal use; interface for swap |
| 2026-11-16 | FGS notification required | Keep sampling after Home on Samsung |
| 2026-11-16 | Segment + label before full 3‑day soak | Daily readability while soak continues |
| 2026-11-16 | OS geocoder + user rename | Free, disclosed, good enough; offline pack optional |

---

*Last updated: 2026-11-17. Update this file when a phase completes or a major constraint changes.*
