# Security: threat model and checklist

Security is reviewed every phase, not at the end. Scope: v1 app plus optional Supabase sync.

## Assets
1. Location history (visits, trips, raw points). Highest sensitivity.
2. Calendar events and notes (can name people and places).
3. Encryption keys (passphrase, recovery key, data key).
4. Auth session tokens.

## Entry points
- The phone itself (lost, unlocked, backed up, shared).
- Supabase REST/Auth endpoints.
- External calls: OS geocoder, weather API, map tiles.
- Exported files (JSON, GPX, ICS) leaving the app.
- Local notifications (visible on lock screen).

## Trust boundaries
Phone OS sandbox | App process | Network | Supabase | Third-party services.

## Threats and mitigations
| Threat | Mitigation | Residual risk |
|---|---|---|
| Cloud database breach | Only ciphertext stored; minimal metadata (kind, day, timestamps) | Metadata reveals activity days |
| Another user reads my rows | RLS `user_id = auth.uid()` on all tables; test with two accounts | Policy bug (tested, not eliminated) |
| Server operator reads my data | Client-side E2EE, key never leaves device unwrapped | Trust in app code |
| Weak or forgotten passphrase | Argon2id with strong parameters; recovery key; clear loss warning | Offline guessing of a weak passphrase if ciphertext leaks |
| Lost or stolen phone | OS lock screen; optional app-level lock later; remote sign-out removes sync access | Local data readable if phone unlocked |
| External services learn my position | Round coordinates for weather; geocoder choice disclosed with off switch; no analytics SDKs | OS geocoder may contact vendor |
| Notification text exposes events | Setting to hide event details on lock screen (add in Phase 6) | User choice |
| Export file left on shared storage | Export via share sheet only, user chooses destination; warn before export | User handling |
| Secrets in the repo | `.gitignore` for env/keys; only anon key in client; no service-role key ever in the app | Human error (add secret scanning in CI later) |
| Vulnerable dependencies | Pin via lockfile once stable; run `dart pub outdated` and advisories check each phase | Zero-days |
| Play/App Store policy breach | Foreground-first permission flow, prominent disclosure, accurate data safety form | Review subjectivity |
| Logs leak coordinates | Local debug log only; coordinates scrubbed from logs by default | Developer mistakes |

## Phase checklist
- [ ] Phase 2: disclosure copy matches real behaviour; permissions requested minimally
- [ ] Phase 3: foreground service type declared; no location in logs
- [ ] Phase 6: lock-screen notification privacy setting
- [ ] Phase 8: export warning; delete-all verified to wipe DB and caches
- [ ] Phase 9: RLS two-account test; wrong-passphrase test; no service-role key in bundle; Argon2id parameters benchmarked on the Samsung
- [ ] Phase 10: dependency audit, privacy policy matches data flows, secret scan clean

## OWASP Mobile focus (for this app)
Insecure data storage, insecure communication (HTTPS only), insufficient cryptography (vetted libraries only, no custom primitives), insecure authentication, privacy controls. Web-only items (XSS, CSRF, CORS) do not apply to the app itself.
