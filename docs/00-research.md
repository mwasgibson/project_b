# Research: Project B (location timeline + calendar app)

Date: 22 Oct 2026. Purpose: back the stack, privacy and store-policy decisions in docs 01 to 06.

**Confidence key:** 🟢 found in sources this session (linked) · 🟡 from general knowledge, verify before relying on it.

---

## 1. Summary of recommendations

| Decision | Recommendation | Confidence |
|---|---|---|
| Framework | Flutter (Dart), with the tracker hidden behind a `LocationTracker` interface | 🟡 (plugin facts 🟢) |
| Local database | SQLite via Drift, optionally encrypted with SQLCipher | 🟡 |
| Cloud sync backend | Supabase (Postgres + Auth + RLS), storing only client-side encrypted data | 🟢 |
| Auth | Email OTP / magic link, only needed for sync | 🟡 |
| Background tracking | Native foreground service (Android) and Core Location (iOS), via a plugin | 🟢 |
| Store risk | Google Play background-location declaration is the main gate | 🟢 |
| Revenue | None in v1 (personal project) | n/a |

---

## 2. Market context: Google Timeline went on-device

- Google moved Maps Timeline from its servers to the user's device, with optional end-to-end encrypted cloud backups. 🟢 [9to5Google](https://9to5google.com/2023/12/12/google-location-history-timeline-device/)
- Timeline stopped being available on the web, and auto-delete defaults to 3 months instead of 18. 🟢 [The Hacker News](https://thehackernews.com/2024/06/google-maps-timeline-data-to-be-stored.html)
- Users signed into several phones now get a separate timeline per device instead of one merged history. 🟢 [BetaNews](https://betanews.com/article/google-could-delete-your-google-maps-timeline-data-in-the-name-of-privacy-so-take-action-now/?mid=1)
- Google also stopped being able to answer geofence warrants for that data once it was not stored server-side. 🟢 [9to5Google](https://9to5google.com/2023/12/12/google-location-history-timeline-device/)

**What this means for Project B**
1. On-device first with optional encrypted backup is where the market already went. It is a safe design, not a risky one.
2. There is a real gap: Google's version has no multi-device merge and no web view. Project B's sync can differentiate on "one timeline across my phones".
3. Google Timeline has no proper calendar or reminders layer. That is Project B's angle.

*Competitors worth a hands-on look before design freeze (🟡, not researched in depth):* Google Timeline, Arc Timeline (iOS), Life360 (family-focused), Samsung Health / Galaxy location features.

---

## 3. Framework choice

| | Flutter | React Native | Kotlin Multiplatform |
|---|---|---|---|
| Language | Dart | TypeScript / JS | Kotlin (+ Swift UI on iOS, or Compose Multiplatform) |
| UI consistency across OSes | Very high (own renderer) | Native widgets, small differences | Native or shared (Compose MP) |
| Background location plugins | Several (see below) | Several (see below) | Write platform code yourself |
| Learning curve for a Python dev | Gentle, typed, one codebase | Gentle if you know JS | Steepest |
| Fits clean minimal light/dark UI | Excellent | Good | Good |

🟡 General assessment. Flutter is the recommendation because one codebase plus a controlled renderer suits a UI-focused app, and Dart is easy to pick up from Python. React Native is a close second; nothing here is a deal-breaker for either.

### Background location plugins (the make-or-break piece)
- **Transistorsoft background geolocation** exists for React Native, Flutter, Capacitor, Cordova and native Swift/Kotlin. It uses motion sensors to detect moving vs stationary and switches location services off while stationary to save battery. 🟢 [pub.dev docs](https://pub.dev/documentation/flutter_background_geolocation/5.1.2/)
  - The Flutter docs say debug builds need no licence, but **Android release builds need a paid licence**. 🟢 same source. (The React Native and Cordova READMEs word the licence rules slightly differently, so re-check on the exact package you install.)
- **Pure Flutter / headless isolates are not reliable** for continuous tracking once the app is killed; at least one plugin author argues for native foreground services instead. 🟢 [pub.dev: background_location_transmitter](https://pub.dev/packages/background_location_transmitter/versions/0.0.1)
- **smart_location** (very new, versions from June 2026) is a native-service Flutter plugin with boot-restart on Android and no dependency on `geolocator`. 🟢 [changelog](https://pub.dev/packages/smart_location/versions/3.5.0/changelog). Its marketing claims ("unkillable", "military-grade") are unverified, and it is a young package, so treat it as a candidate to test, not a given.

**Decision:** put tracking behind an interface (`LocationTracker`). Prototype with Transistorsoft in debug (free), run a head-to-head test against a free native-service plugin on your Samsung, and decide on the licence before any release build. No deadline means you can afford that test.

### Samsung warning 🟡
Samsung One UI is known for aggressive background-app killing and battery optimisation. Since your test device is a Samsung, you will hit this early. Plan for an in-app "keep tracking alive" guide (battery optimisation exemption) and test with the screen off for hours.

---

## 4. Store policy and permissions

### Google Play 🟢
- Any app using background location must be approved via the **permissions declaration form** in Play Console. 🟢 [Play Help](https://support.google.com/googleplay/android-developer/answer/9799150?hl=en)
- You must submit a **short video** showing the feature that needs background location, and list every feature that uses it. 🟢 [Sentiance summary of Play policy](https://docs.sentiance.com/important-topics/playstore-location-access-review)
- You need a **prominent in-app disclosure** (not buried in the privacy policy) that mentions location use even when the app is closed, shown **before** the system permission prompt. Ask for foreground location first and only request background when the user turns tracking on. 🟢 [inDigitall guide](https://documentation.indigitall.com/docs/background-location-fix)
- Using a foreground service to read location can count as background location for policy purposes. 🟢 [Play Help](https://support.google.com/googleplay/android-developer/answer/9799150?hl=en)
- Apps targeting Android 14+ must declare foreground service types in Play Console; the `location` type needs `FOREGROUND_SERVICE_LOCATION` plus a location permission. 🟢 [Play Help](https://support.google.com/googleplay/android-developer/answer/13392821?hl=en)
- Policy notes mention a location button requirement for apps targeting Android 17+, but that is about foreground location access. Check it when you pick a target SDK. 🟢 [Play Help](https://support.google.com/googleplay/android-developer/answer/9799150?hl=en)

### Apple App Store 🟡 (not researched this session)
- Background tracking needs "Always" location authorisation plus the Background Modes capability, and a clear purpose string.
- iOS offers low-power APIs worth using: significant-location-change monitoring and visit monitoring (`CLVisit`).
- An Apple Developer Program membership (paid, yearly) is required for TestFlight and App Store release. Without it you can usually only side-load to your own devices with short-lived signing.
- Offering third-party sign-in (e.g. Google) can trigger Apple's "Sign in with Apple" rule. That is one reason v1 uses email OTP only. Verify current guideline wording before adding social login.

**Action for you:** you have a Mac but no developer account. Delay buying it until Phase 9 (store prep). Debug on your own iPhone only if you have one; otherwise use the iOS simulator, which cannot fully test real background location, so iOS tracking validation will be limited until you have a device.

---

## 5. Backend for optional sync

| | Supabase | Firebase | Own FastAPI + Postgres |
|---|---|---|---|
| Data model | Postgres (relational, RLS) | Firestore (NoSQL) | Whatever you choose |
| Free tier | Free plan: 500 MB DB, 50k MAU, 1 GB storage 🟢 | Free Spark plan; paid Blaze is usage-based 🟢 | Hosting cost only |
| Spend risk | Spend cap on by default on paid plan 🟢 | Blaze has no default spending cap 🟢 | You control it |
| Gotchas | Free projects pause after 1 week of inactivity, max 2 active projects 🟢 | Per read/write pricing can spike 🟢 | You maintain everything |
| Offline sync | Realtime lacks Firebase's deep offline conflict handling 🟢 | Strong built-in offline support 🟢 | Build yourself |
| Lock-in | Open source, self-hostable 🟢 | Proprietary NoSQL, harder to leave 🟢 | None |
| Fit for a Python dev | Good (Postgres, SQL, can add Python services later) | OK | Best fit, most work |

Sources: [Jet Admin comparison](https://www.jetadmin.io/blog/supabase-vs-firebase/) (checked 26 Sep 2026, vendor-neutral by its own statement), [DEV Community comparison](https://dev.to/kimcomplete/supabase-vs-firebase-how-the-two-backends-compare-2026-3co4), [Rapidevelopers](https://www.rapidevelopers.com/vs/supabase-vs-firebase).

**Decision: Supabase.** Reasons: the free tier fits a personal project, you get SQL, there is a self-host exit if pricing changes, and the one weakness (offline conflict handling) does not hurt because the phone is the source of truth and we write our own small sync protocol. Pricing details drift; re-check on supabase.com/pricing before launch.

**Why the server only stores ciphertext:** Row Level Security protects against other users, not against you or a database breach. With client-side encryption, even a leaked database reveals nothing about movements. This matches what Google moved toward.

---

## 6. End-to-end encryption design notes 🟡
- Derive a key from a user passphrase with Argon2id, generate a random data key, and store the data key *wrapped* by the passphrase key on the server. A printed recovery key wraps it a second way.
- Encrypt each sync record with an authenticated cipher (XChaCha20-Poly1305 or AES-GCM) with a unique nonce.
- Cost of this model: **forgetting the passphrase and recovery key means the cloud copy is gone**. The app must say that plainly at setup.
- Server-visible metadata should be minimal: record id, kind, day bucket, version, timestamps.
- Use a vetted library (libsodium bindings or `cryptography` for Dart). Do not write primitives yourself.

---

## 7. Services for the feature list 🟡 (verify terms at build time)

| Need | Option | Notes |
|---|---|---|
| Place names (reverse geocoding) | Platform geocoders via the `geocoding` package (free, on-device calls to OS) | Quality varies. Google Places gives better "Java House" style names but is paid and sends coordinates to Google |
| Alternative geocoding | Self-hosted or public Nominatim | Public instance has strict usage rules and is not meant for bulk use |
| Weather | Open-Meteo (no API key, free for non-commercial use) | Re-check terms; keep it behind a `WeatherProvider` interface |
| Map display | `flutter_map` with an OSM-based tile provider, or MapLibre | Public OSM tiles have a usage policy; use a proper tile provider for release |
| Local reminders | `flutter_local_notifications` | Scheduled local notifications; no server needed |
| Device calendar export | `.ics` export first, native calendar plugin later | Avoids extra permissions in v1 |

**Privacy trade-off to decide:** every external call (geocoding, weather) leaks an approximate location. Mitigation baked into the plan: round coordinates (e.g. ~1 km for weather), and tell the user.

---

## 8. Legal and privacy 🟡 (not legal advice)
- Location history is sensitive personal data under most privacy laws. You are in Kenya, so the **Kenya Data Protection Act, 2019** is relevant if you ever publish for others; if EU users install it, GDPR applies too. Even for a personal project, a published store listing needs a privacy policy.
- Needed regardless: clear consent, a way to export and delete all data, minimal retention, and no selling or sharing.
- Fine in personal use; revisit before a public release.

---

## 9. Key risks

| Risk | Impact | Mitigation |
|---|---|---|
| Background tracking killed by OS (esp. Samsung) | Gaps in timeline | Native foreground service, battery-optimisation guide, motion-based wake, gap detection UI |
| Play Store rejects background location | Cannot publish | Follow declaration, disclosure, video steps; foreground-first permission flow |
| Plugin licence cost / abandonment | Cost or rewrite | `LocationTracker` interface, test free alternative |
| Battery drain | Users uninstall | Three modes, motion-based stop, auto saver at low battery |
| Lost passphrase | Cloud data unrecoverable | Recovery key, clear wording, local data unaffected |
| iOS testing without a device | Untested tracking | Get a real iPhone before Phase 3 iOS work |
| Scope creep from the feature list | Never ships | Strict MVP in doc 01 |

---

## 10. Open research items (not done yet)
- Hands-on competitor review (Arc, Google Timeline).
- Apple's current App Review wording for background location and Sign in with Apple.
- Exact Transistorsoft licence price and terms.
- Head-to-head battery test of plugins on the Samsung.
- Current Open-Meteo, Nominatim and tile-provider terms.
