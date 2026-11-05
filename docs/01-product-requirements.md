# Product Requirements: Project B

(Working name. Rename when you pick one.)

## Overview
Project B is a privacy-first mobile app (Android + iOS) that, with the user's permission, records where they go in the background and turns it into a readable timeline of places visited and trips taken. The timeline lives inside a calendar, so past movements, upcoming events and reminders sit in one place, with weather alongside. Data is stored on the phone first. Cloud sync is optional and end-to-end encrypted, so only the user can read their history.

Problem: people forget where they went and when, and the main existing option (Google Timeline) is tied to Google, has no calendar or reminder layer, and no multi-device merge.

## Goals and success metrics
| Goal | How we know it worked |
|---|---|
| Tracking is reliable | Over a 7-day personal test, less than 5% of waking hours have unexplained gaps |
| Tracking is cheap on battery | Balanced mode costs under 5% extra battery per day on the test Samsung |
| Timeline is readable | A day shows named visits and trips with start/end times, no raw coordinates needed |
| Privacy is real | App works fully with no account; cloud copy is unreadable without the user's key |
| It ships | MVP running on both platforms for the owner's own use |

(Targets are starting points; adjust after the first week of real use.)

## Users and roles
| Role | Description | Key needs |
|---|---|---|
| Device owner | The only role in v1. Installs the app, grants permissions, views their own data. | Trust, low battery use, simple timeline, control over deleting data |
| Synced user | The same person after enabling cloud sync (email sign-in). | Same timeline on several phones, recoverable if a phone is lost |

No admin role. No other users see anyone's data.

## Features

### MVP
**F1. Onboarding and permissions**
- User story: As a device owner, I want to understand what is recorded before I grant access so that I can trust the app.
- Acceptance criteria:
  - A plain-language disclosure screen explains that location is collected in the background, including when the app is closed, before any system prompt.
  - Foreground location is requested first; background ("Always") is requested only when the user turns tracking on.
  - If permission is denied, the app still opens, shows an explanation, and offers a path to settings.

**F2. Background location tracking**
- User story: As a device owner, I want my movements recorded automatically so that I do not have to log anything.
- Acceptance criteria:
  - Tracking runs with the app closed and continues after reboot while enabled.
  - Tracking stops sampling when the phone is stationary and resumes on movement.
  - A persistent indicator (Android foreground-service notification; iOS system indicator) shows tracking is on.
  - Pause/resume control from the home screen and the notification.

**F3. Battery modes**
- User story: As a device owner, I want to trade precision for battery so that tracking fits my day.
- Acceptance criteria:
  - Three modes: High precision, Balanced (default), Battery saver.
  - Optional rule: auto-switch to Battery saver when battery is at or below a user-set level (default 15%).
  - Current mode and the rule are visible in settings.

**F4. Timeline (visits and trips)**
- User story: As a device owner, I want each day shown as places and trips so that I can recall what I did.
- Acceptance criteria:
  - Raw points are grouped into visits (stayed in one place) and trips (moving between places).
  - Each visit shows a place name (when available), arrival and departure time, and duration.
  - Each trip shows distance, duration and a route line on a map.
  - User can rename a place, merge or delete a visit, and delete a whole day.
  - Works offline.

**F5. Place labelling**
- User story: As a device owner, I want places named automatically so that I see "Java House" not coordinates.
- Acceptance criteria:
  - New visits are labelled via reverse geocoding; if offline, they stay unlabelled and are labelled later.
  - A setting turns auto-labelling off; visits then stay unlabelled until the user names them.
  - A place the user has renamed once keeps that name for future visits within about 100 m.
  - Place lookup goes through the phone's built-in geocoder, which may contact the platform vendor's service; the app discloses this in settings (see doc 02).

**F6. Calendar with events and reminders**
- User story: As a device owner, I want to see my days, add events and set reminders so that planning and memory live together.
- Acceptance criteria:
  - Month and day views; each day shows timeline entries and events.
  - Create, edit and delete events (title, start, end, optional location, notes).
  - Time-based reminders as local notifications, with offline scheduling.
  - Events can be exported as `.ics`.

**F7. Weather**
- User story: As a device owner, I want weather on my calendar so that I can plan around it.
- Acceptance criteria:
  - Current conditions and a multi-day forecast for the current location, and for an event's location if set.
  - Last result is cached and shown (marked as stale) when offline.
  - Weather lookups use rounded coordinates.

**F8. Data control and settings**
- User story: As a device owner, I want to export or erase everything so that I stay in control.
- Acceptance criteria:
  - Export all data to a file (JSON; GPX for routes).
  - Delete all data, with a confirmation step.
  - Retention setting for raw points (default 30 days; visits and trips are kept).
  - Light, dark and system themes.

**F9. Optional encrypted cloud sync**
- User story: As a device owner, I want my timeline on my other phone and safe if I lose this one, without anyone else reading it.
- Acceptance criteria:
  - Sign-in is required only to turn on sync; the app is fully usable without an account.
  - Sign-in by email one-time code.
  - On enabling, user sets a passphrase and receives a recovery key; app states plainly that losing both means cloud data cannot be recovered.
  - Data is encrypted on the phone before upload; the server never holds readable location data.
  - Changes sync both ways when online; offline edits queue and sync later.
  - User can turn sync off and delete cloud data.

### Later (not MVP)
- Gallery connection: link photos to timeline slots by timestamp and location.
- Location-based reminders (geofences): "remind me when I'm near X".
- Weather-aware suggestions for outdoor events (rain alert before an event).
- Year / month in review summaries (distance, new places).
- Share a day, trip or recap as an image or link.
- Sync with other apps: device calendar two-way, Google Fitness / Health imports.
- Google and Apple sign-in.
- Home/work auto-detection and place categories.
- Web viewer.

## Out of scope (deliberately)
- Payments, subscriptions or ads (personal project, no revenue).
- Social features, friends or family location sharing.
- Real-time live location sharing.
- Selling, analysing or sharing user location data.
- Server-side processing of readable location data.

## Assumptions and open questions
Assumptions
1. Single-user app; each person has their own private data.
2. Tracking data volume stays small enough for on-device SQLite.
3. Free services suffice for weather, geocoding and maps in personal use.

Open questions
1. App name and bundle/package id (e.g. `com.yourname.projectb`).
2. Will other people eventually install it, or is it staying personal? This affects privacy policy, store review and geocoding choice.
3. Which place-name quality is acceptable (free platform geocoder vs paid Google Places)? See research doc section 7.
4. Do you have an iPhone for real-device testing?
5. Raw point retention default of 30 days: confirm or change.
