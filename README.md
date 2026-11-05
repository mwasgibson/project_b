# Project B

Privacy-first location timeline and calendar for Android and iOS. Working name.
Records where you go (with permission), turns it into visits and trips, and puts them in a calendar with reminders and weather. Data lives on the phone; cloud sync is optional and end-to-end encrypted.

**Status:** Phase 1 (foundations) written, not yet compiled. See `tasks/todo.md`.

## Quick start (Mac)
```bash
# Install FVM first: https://fvm.app/documentation/getting-started/installation
# optional: choose your package id first (hard to change after publishing)
ORG=com.yourname.projectb ./tool/bootstrap.sh
fvm flutter run        # pick the Samsung or the iOS simulator
```
`.fvmrc` pins Flutter 3.38.10, which works on macOS 13; the newer Flutter SDK currently on the machine requires macOS 14. Run `fvm use 3.38.10` to create the project SDK link; the VS Code workspace is configured to use it instead of a globally installed Flutter. `bootstrap.sh` installs the pinned SDK through FVM, generates the `android/` and `ios/` folders, resolves the declared dependencies, runs Drift code generation, then analyzes and tests the project.

Needs: FVM, Android Studio, and a Java 17–24 JDK for Android builds (the Gradle 8.14 wrapper is not compatible with Java 25). Xcode is required for iOS. Run `fvm flutter doctor` first; if it selects Java 25 from Android Studio, install JDK 17 and select it with `fvm flutter config --jdk-dir=<JDK_HOME>`.

## Docs
| Doc | What |
|---|---|
| `docs/00-research.md` | Research and sources behind the decisions |
| `docs/01-product-requirements.md` | Features F1 to F9, MVP vs later |
| `docs/02-technical-requirements.md` | Stack, architecture, non-functional needs |
| `docs/03-app-flow.md` | Screens, routes, flows, edge cases |
| `docs/04-design-brief.md` | Visual system, components, accessibility |
| `docs/05-backend-schema.md` | Local and cloud schema, API |
| `docs/06-implementation-plan.md` | Phases and progress log |
| `docs/07-decisions.md` | Architecture decision records |
| `docs/08-security.md` | Threat model and security checklist |

`docs/` is the living copy. Update the affected doc whenever code changes behaviour.

## Layout
```
lib/
  core/        theme, router, database, settings, shared widgets
  domain/      interfaces the rest of the app depends on (LocationTracker)
  features/    timeline, calendar, weather, settings (screens; logic added per phase)
test/          mirrors lib/
tool/          bootstrap script
env/           *.example.json only; real env files are gitignored
```

## Rules of the repo
- Local-first: every feature works with no account and no network.
- External services sit behind interfaces so they can be swapped.
- No secrets in git. No analytics or ad SDKs. No crash reporter that uploads coordinates.
- Generated `*.g.dart` files are not committed.
