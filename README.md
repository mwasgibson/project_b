# Project B

Privacy-first location timeline and calendar for Android and iOS (working name).
Records where you go (with permission), turns movement into visits and trips, and shows them on a timeline and calendar with weather. Data stays on the phone; cloud sync is optional and planned as encrypted (Phase 9).

**Status:** Phases 0–8 core on `main` (tracking through data control, maps polish). Phase 9 sync deferred. See [`docs/06-implementation-plan.md`](docs/06-implementation-plan.md) and [`docs/09-build-roadmap.md`](docs/09-build-roadmap.md).

## Quick start (Mac)

```bash
# FVM: https://fvm.app/documentation/getting-started/installation
ORG=com.yourname.projectb ./tool/bootstrap.sh   # optional once
fvm flutter pub get
fvm flutter run        # Samsung or iOS simulator
```

`.fvmrc` pins Flutter 3.38.10. Needs FVM, Android Studio, and a Java 17–24 JDK for Android (Gradle 8.13 is not compatible with Java 25). Xcode for iOS. Run `fvm flutter doctor` first.

**Launcher icon:** After pulling icon changes, **uninstall** the old app once, then `fvm flutter clean && fvm flutter run`, so the teal adaptive icon replaces a cached Flutter logo.

## Docs

Full index: [`docs/README.md`](docs/README.md).

| Doc | What |
| --- | --- |
| `docs/00-research.md` | Research |
| `docs/01-product-requirements.md` | Features F1–F9 |
| `docs/02-technical-requirements.md` | Stack, architecture |
| `docs/03-app-flow.md` | Screens and flows |
| `docs/04-design-brief.md` | Visual system |
| `docs/05-backend-schema.md` | Schema |
| `docs/06-implementation-plan.md` | Phases and checklists |
| `docs/07-decisions.md` | ADRs |
| `docs/08-security.md` | Security |
| `docs/09-build-roadmap.md` | Lived build path |
| `docs/10-code-health.md` | Code-quality snapshot |

## Layout

```text
lib/
  core/        theme, router, database, settings, widgets
  domain/      interfaces (LocationTracker, PlaceResolver, WeatherProvider)
  features/    timeline, calendar, weather, settings, map, tracking, places
test/
tool/
env/           *.example.json only
```

## Rules

- Local-first: works with no account and no network for core features.
- External services behind interfaces.
- No secrets in git. No analytics or ad SDKs. No crash reporter that uploads coordinates.
- Generated `*.g.dart` files are not committed.
