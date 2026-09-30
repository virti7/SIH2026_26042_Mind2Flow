# Android Debug APK — Supabase Auth Build

## Root cause this file exists for

`SUPABASE_URL` and `SUPABASE_ANON_KEY` are **compile-time**
`String.fromEnvironment` values (`lib/core/config/supabase_config.dart`).
If the APK is built **without** `--dart-define`, the app compiles with the
placeholder URL/key, `SupabaseConfig.isConfigured` is `false`, and every
login/signup immediately fails **without any network traffic** — which looks
like "no internet" but is actually a missing build configuration. Flutter Web
worked because `flutter run` was launched with the defines; the APK was not.

## Correct debug APK command (USB testing with local FastAPI)

```powershell
flutter build apk --debug `
  --dart-define=SUPABASE_URL=https://<your-project-ref>.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=<your-public-anon-or-publishable-key> `
  --dart-define=BACKEND_URL=http://127.0.0.1:8000
```

Then, with the phone on USB and the backend running on the PC:

```powershell
adb reverse tcp:8000 tcp:8000
adb install build\app\outputs\flutter-apk\app-debug.apk
```

Notes:

- Use the **same** Supabase project (URL + public anon/publishable key from
  the Supabase dashboard → Project Settings → API) for Web and Android.
- Never put the **service-role key**, database password, JWT secret, or
  `SARVAM_API_KEY` in `--dart-define` or Flutter code (backend only).
- `BACKEND_URL` is independent of authentication: Supabase login must work
  even with FastAPI stopped. `http://127.0.0.1:8000` on the phone reaches
  the PC only via `adb reverse`.
- Do NOT add cleartext-HTTP exceptions for Supabase: Supabase Auth uses
  HTTPS. (`android:usesCleartextTraffic="true"` exists only for the local
  `http://127.0.0.1:8000` backend during USB testing.)

## Verifying on device

```powershell
adb logcat -c
# launch the app, attempt login, then:
adb logcat -d | Select-String "SupabaseConfig|AuthSelfTest|\[Auth\]"
```

Expected (debug build, correct defines):

- `[SupabaseConfig] platform=android configured=true urlHost=<ref>.supabase.co`
- `[Auth] Supabase initialization started`
- `[Auth] Supabase initialization successful`
- `[AuthSelfTest] clientInitialized=true urlConfigured=true ... endpointReachable=true ...`

If instead you see `configured=false` + `Supabase configuration is missing.
Build with SUPABASE_URL and SUPABASE_ANON_KEY.`, the APK was built without
the defines — rebuild with the command above. Only hostname/cause/status
are logged; keys and tokens are never printed.

## Backend reachability diagnostics (FastAPI)

Device internet (`online=true`) and FastAPI reachability
(`backendReachable=true/false`) are independent states — the app never
assumes one from the other. Worksheet generation probes exactly the
configured `BACKEND_URL` (no silent `127.0.0.1` ⇄ `10.0.2.2` guessing) via
`GET <BACKEND_URL>/api/v1/health` (alias `/health`), 3s timeout.

Watch in a debug build:

```powershell
adb logcat -d | Select-String "BackendDiag|WorksheetGenerate|ApiConfig"
```

- `[ApiConfig] platform=android baseUrl=... explicit=...` — the URL this
  build actually uses.
- `[BackendDiag] platform=android configuredBackendUrl=... healthUrl=... networkOnline=... backendReachable=... failureReason=...`
  with `failureReason` one of `offline|malformedUrl|dnsFailure|connectionRefused|connectionTimeout|httpError|unknown`.
- `[WorksheetGenerate] platform=... networkOnline=... backendUrl=... backendReachable=... mode=...`

Checklist when `networkOnline=true` but `backendReachable=false`:

1. `failureReason=connectionRefused` on `http://127.0.0.1:8000` (physical
   phone) → `adb reverse` mapping is missing: run
   `adb reverse tcp:8000 tcp:8000` and verify with `adb reverse --list`.
2. Emulator → rebuild with `--dart-define=BACKEND_URL=http://10.0.2.2:8000`.
3. LAN IP → phone must reach the host and uvicorn must listen on `0.0.0.0`
   (see `backend/.env` `HOST`), not `127.0.0.1`.
4. `failureReason=connectionTimeout` → FastAPI up but `/api/v1/health`
   slow (e.g. database hanging); check backend logs.
5. `failureReason=httpError` → server answered non-200; check backend logs.

A backend failure never signs the teacher out (Supabase session is
independent) and queued worksheets sync on the next retry once the server
is reachable — no reinstall or re-login needed.
