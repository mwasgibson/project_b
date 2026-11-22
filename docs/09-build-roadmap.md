# Build roadmap: what we actually did

This document records **how Project B was built in practice**, not only how it was planned. It sits beside `docs/08-security.md` and `docs/08-code-health.md`. Where plan and path diverged, the reason is written down so future phases stay honest about constraints.

**Audience:** you (and anyone revisiting the repo months later).  
**Canonical file:** this is `docs/09-build-roadmap.md` — not `07-build-roadmap` (that path only redirects here).

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
| **Personal / no revenue** | Prefer free stack: Geolocator, OS geocoder, Open-Meteo. Paid Transistorsoft left as a *possible* swap behind the same interface. |
| **Supabase only at Phase 9** | Explicit user decision. No premature auth, keys, or sync UI. |
| **Display name “Project B”** | Underscore removed from user-facing name; package/repo naming left stable. |
| **Real device is Samsung SM-A176B** | Keep-alive / battery tip, FGS notification, and smoke tests targeted at aggressive OEM optimisation. |

### Engineering rules (from doc 06, kept in force)

1. External capabilities behind interfaces: `LocationTracker`, `PlaceResolver`, `WeatherProvider`, (later) `SyncBackend`.
2. Local-first: feature works offline before any network.
3. Each phase ends with something runnable on the Samsung.
4. Finish a phase’s core before starting the next (soft rule — calendar/weather may run while tracking soaks).

---

## 2. Planned vs actual sequence

```text
Plan:   0 → 1 → 2 → 3 (risk) → 4 → 5 → 6/7 → 8 → MVP soak → 9 → 10
Actual: 0 → 1 → 2 → 3 core → 4 → 5 → 6 → 7 → 8 polish  |  open: 3 harden, 9, maps…
```

We followed **risk-first** order: permissions and tracking before polish. Segmentation and labelling landed before a formal multi-day battery log because outdoor smoke tests already showed points, and readable visits make daily use valuable while hardening continues.

---

## 3. Phase-by-phase narrative

### Phase 0 — Setup

**Goal:** Clean repo, docs, app runs on Samsung and iOS simulator.

**What we did:** Flutter + FVM, docs 01–06, CI baseline, display name Project B.

**Friction:** iOS simulator failed with `objective_c` / `xcrun --show-sdk-path` because Xcode lived under Downloads. Fixed with `xcode-select` and license acceptance — not an app bug.

---

### Phase 1 — Foundations

**Goal:** Shell, theme, Drift schema, settings.

**What we did:** Feature folders, Riverpod, go_router four tabs, light/dark/system, Drift tables mirroring doc 05, reusable empty states and chips.

---

### Phase 2 — Onboarding and permissions (F1)

**Goal:** Honest permission flow.

**What we did:** S1–S3, `PermissionService`, Android manifest / iOS plist strings, Timeline cards for denied / services-off / “Allow all the time”.

**Bug and fix:** After S3, “Start tracking” **re-looped** the disclosure. Fix: `background_disclosure_shown` + open system settings when permanently denied.

---

### Phase 3 — Tracking engine (F2, F3)

**Goal:** Points on disk with the app backgrounded.

**What we shipped:**

- `LocationTracker` + `GeolocatorLocationTracker` (free).
- `raw_points` writes; Android FGS notification; modes high / balanced / saver.
- `TrackingSession`: pause/resume/**stop**, resume if `tracking_enabled`, gaps, auto-saver, stale banner.
- S14 tracking settings + battery tip (phone-agnostic wording).

**Smoke test (2026-11-16 / 19):** Outdoor / near-home on SM-A176B; FGS bind and position updates.

**Still open in Phase 3:** swipe-from-recents headless, boot receiver, formal multi-day battery log.

---

### Phase 4 — Segmentation and timeline (F4)

**What we shipped:** Pure `Segmenter`, visits/trips, Timeline list with left rail, soft-delete, refresh (“Find visits” / merge).

**Later polish (2026-11-19):** Same-place fragments (overlapping times, plus-code vs named place) **merge into one visit** (~300 m / same placeId / same name). Gaps show when tracking was paused or off — not a second place card.

**Deferred:** full day map (S6), trip polyline map (S8).

---

### Phase 5 — Place labelling (F5)

**What we shipped:** `PlaceResolver` / platform geocoder, radius match, auto-label toggle + disclosure, user rename.

**Later (2026-11-19):** **Places list (S15)** — unique places with visit **count**; detail shows every visit date/time. Nearby duplicate place rows consolidated (~120 m).

---

### Phase 6 — Calendar + reminders

**What we shipped:** Calendar as **movement log** (visits/trips primary), local events, reminders (`flutter_local_notifications`), day agenda merge.

**User direction:** Calendar is “a place to log all my trips and visits,” not only standalone events.

---

### Phase 7 — Weather

**What we shipped:** Open-Meteo provider, ~1 km rounded coords, local cache, Weather screen, offline/stale label.

**Optional left:** weather chip on calendar day.

---

### Phase 8 — Data control + polish

**What we shipped:**

- Export JSON / GPX; typed `DELETE` wipe; retention (detailed history age).
- Tracking **on/off** (not only pause); controls under Settings → Tracking.
- **Raw points hidden from UI** (still used for segmentation).
- Soft-delete visits → Deleted visits (restore / permanent).
- Timeline design rail; adaptive **app icon** (teal `#0F766E`, pin + stem).

---

## 4. Cross-cutting incidents

| Issue | Root cause | Fix |
| --- | --- | --- |
| Theme change kicked user to Timeline | `routerProvider` **watched** onboarding stream | Stable router + refresh only when onboarding value changes |
| Permission loop on Start tracking | Re-prompting background after disclosure | Persist disclosure shown; system settings when permanent |
| Rename red screen under debugger | `TextEditingController` disposed while sheet animating | Stateful rename dialog owns controller lifecycle |
| “Kwa Good Neighbour” many times | Merge required non-overlap; different placeIds / plus codes | Merge overlap + proximity + same name; consolidate places |
| Duplicate roadmap files | Short note written as `07-build-roadmap` | Canonical narrative stays in **this** file (`09`) |

---

## 5. Architecture that stayed true

```text
LocationTracker  → raw_points (not user-facing)
Segmenter        → visits / trips / gaps
PlaceResolver    → places → visit.place_id + label_state
UI               → repositories / session only (not plugins)
```

---

## 6. What “done” means now (through Phase 8 core)

**Usable daily on Samsung:**

- Permissions, track with notification, pause/stop, modes, auto-saver, gaps.
- One visit per continuous stay; places list with history; calendar movement log; weather; export/delete.

**Not claiming yet:**

- Multi-day gap-free trail under One UI with swipe-kill and reboot.
- Measured battery overhead over a week.
- Map day/trip views.
- Encrypted multi-device sync (Phase 9).

---

## 7. Next

1. **MVP soak** — real daily use; note gaps and merge edge cases.
2. **Phase 3 hardening** in parallel (boot, swipe-kill if needed, battery log).
3. **Phase 9 — Encrypted sync** (Supabase) when ready.
4. Optional: day/trip maps, calendar weather chip, more merge tests.
5. **Phase 10 — Release prep** only if distributing beyond personal use.

---

## 8. Decision log (short)

| Date | Decision | Reason |
| --- | --- | --- |
| 2026-10 | Docs before code | Align product, privacy, schema |
| 2026-11-10 | Name = Project B; no iPhone; Supabase @9 | User constraints |
| 2026-11-10 | Geolocator not Transistorsoft first | Free personal use; interface for swap |
| 2026-11-16 | FGS notification required | Keep sampling after Home on Samsung |
| 2026-11-16 | Segment + label before full 3‑day soak | Daily readability while soak continues |
| 2026-11-16 | OS geocoder + user rename | Free, disclosed, good enough |
| 2026-11-19 | Points not shown in UI | Timeline is places, not samples |
| 2026-11-19 | Aggressive same-place visit merge | One stay → one row |
| 2026-11-19 | Roadmap lives in docs/09 | Avoid competing “07-build-roadmap” |

---

*Last updated: 2026-11-22. Update this file when a phase completes or a major constraint changes.*
