# Changelog

All notable changes to this project are documented here.

## [Unreleased]

- **HTTPS first, plain HTTP only when allowed, and a certificate you can trust:** the panel used to probe plain HTTP first and could fall back to it without asking. Now every connection (REST and WebSocket) starts over HTTPS. Plain HTTP is a second try only to this same machine (the default `127.0.0.1`, which never leaves it) or, when the new **Security** window allows it, to a server on the local network (outside it, only when that is allowed too); a server once seen over TLS is never retried in plain HTTP. A server with a self-signed certificate is trusted by its SHA-256 fingerprint: **Security** reads it from the server, shows it, and keeps it only after you trust it and save; from then on only a certificate with exactly that fingerprint is accepted. A CA certificate can be given instead. Security is reachable from the sign-in screen and from Settings, in all eight languages, and a failed secure connection now says so and points to it. Tests added, including a real TLS server with a self-signed certificate (203 in all).

- **The sign-in screen offers the machine the panel is mounted on:** the server address is pre-filled with `127.0.0.1` (port 3000) instead of an address of some other network, since the panel is fixed to the Compute Module that runs the server. A panel meant for another server still types the address or scans for it. The on-screen keyboard for the touch panel is not part of this change. 2 tests.
- **README in the universal layout:** the README and its seven translations follow the layout that the four families share (22 sections in a fixed order), with an architecture picture and a repository-structure picture drawn from `docs/architecture.json` and `docs/structure.json`; the CI validator checks both pictures and the file tree.

- **The layout of the README is checked in the CI:** the validator runs `tools/universal_readme_check.py` and lists, as a warning, what differs from the universal layout of the README.

## [0.2.7] - PLAY asks first and conditional writes

### Firmware and protocol

- **Audit record for administrators.** An Audit record button under the reservations opens the lines the server wrote down about the changes that matter, newest first, with a filter by type, robot and number of lines. Verifying checks the chain of SHA-256 hashes twice: the server over the whole record and the program over the lines it was given (a changed line, a replaced line whose successor still names the old one; a filtered window only shows gaps). The lines can be copied as stored (`.jsonl`). Says why when it can not read (not an administrator, older server, expired session, no network, record switched off or locked off).
- Tests for the three rules (`contract_v2_test.dart`, with SHA-256 vectors) and for the behaviour against a local server (`robot_view_model_conditional_test.dart`: the header, the 412, the table, the older server, the audit record).
- The live connection no longer falls back to `/ws?token=`: the token travels only as the `hydra.bearer` subprotocol, which every server since the subprotocol was added answers and which the server now requires (it refuses the address form by default). A server that does not answer it is reported as a failed connection instead of being handed the token in the address. A token that a subprotocol cannot carry is reported as rejected and no connection is attempted; `ServerInfo.wsUrl()` (unused) is gone. Three tests replace the one that expected the fallback.
- The README and the architecture notes describe the subprotocol as the only form.

### Programs and windows

- New test of the per-robot STOP: a real long press (as a finger on the touch panel gives it) reaches the command through the Tooltip that wraps the button, a quick tap does not, and a stop that is not available does nothing. It checks the widget, not the panel: it has not been tried on the real touch screen.
- **PLAY asks first.** Before a trajectory starts the app shows the robot, its recorded points, the speed and who has it reserved (a robot reserved by someone else says the server will refuse the command). It is on by default and is turned off in Settings; a robot that is already playing is not asked again, and the choice is kept. In the eight languages, with tests of the rules, the option and the dialog (cancelling sends nothing).
- **Conditional writes.** Every reservation, release and robot command carries the revision of the robot this program last saw (`If-Match`, kept per robot from the answers of the server and from `GET /api/robot/:id`). When someone else changed the robot in between, the server answers 412: nothing is applied, the change on screen is undone, the robot is read again so the screen shows what it is now, and the message says so in the eight languages. STOP is never conditional, a write is not conditional while another write to the same robot is on its way, and a take-over is never conditional. A choice in the list of reservations (kept on this computer) selects Standard (reservations, the table and the one-off commands; the default), Strict (everything but STOP) or Off.
- **The server pushes the reservations** (WebSocket message `claims`): the list and the arming of the jog follow at once and the 15 second poll of the Control screen rests while a push is recent.
- **Reservations.** The Control screen shows who holds the selected robot (nobody, this display, your account on another device, another account), reserves and releases it, and lists every reservation of the server. Reservations stay optional.
- **Controller id.** The display keeps one controller id for the installation and sends it with every reserve, release, jog-arm and command (body and `X-Controller-Id` header), so a reservation belongs to the account and to this display. The refusals of the server read differently: another account, your account on another device or window, controller id required, and jog not armed.
- The notes in `lib/network/discovery.dart` say what was really run (Windows desktop, and a Linux build under WSL2) instead of contradicting the README.
- **Take control (administrators only).** On a robot someone else holds, an administrator's session shows a **Take control** button that asks for confirmation and then reserves the robot with `force: true`. The role comes from the session token (the server checks it again); an operator never sees the button and nothing is sent if it is asked for anyway. Texts in the eight languages and unit tests for the role, the rule and the request.

### Tests, builds and checks

- CI builds the Linux app (`flutter build linux --release`) after installing the desktop build dependencies, so a change that breaks the native build or a plugin is caught before a release.
- The eight languages carry the new texts, with their tests.
- Building no longer changes the version; raising it is the explicit `bump` command (`python tools/hydra_project_tool.py bump`). The build scripts only report the version they built, and CI fails if a build script runs a bump.
- Added `tools/hydra_project_tool.py`: the same `validate`, `test`, `version`, `status` and `bump` commands in every repository. The checks run with `HYDRA_UMC_CI=1` and fail if the version changes; only `bump` changes it.

### Documentation

- The README, in the eight languages, names HYDRA-UMC-SERVER (not STUDIO) as the server the panel talks to.

### Other changes

- **The XY table jog is one atomic `table` command**, relative to where the table is (checked as a whole against the limits of the model before it is sent and counted as a jog for the arming of the jog); a server that predates the command is detected and gets the jogs that did the same before.
- **Safety limits.** The limits of the robot's model are read from the server: a jog step above the limit is not sent (it says which limit), and when the administrator requires it the jog waits for an explicit **Arm jog** (with a countdown) that ends by itself, with STOP, or on release.
- The banner follows the animated style of the ecosystem banners, with the name, the kind and the technologies of the project.
- Removed the unused `postSettings` and `HydraState.merge`.

## [0.2.6]

- Maturity is functional: nothing here has been verified on real hardware yet.
- The READMEs say, in the eight languages, what is planned and what has only been tested against fakes, emulators or fixtures, and carry a short safety and security status note.

## [0.2.5] - Reconnect back-off that stays a back-off, and tolerant readers of server data

- **Reconnect back-off:** the wait before a reconnect was `3 s x 2^(failed attempts - 1)` computed in 64-bit integers, which overflows at 62 consecutive failed attempts (about half an hour with a server that stays down): the wait fell to zero and the app reconnected every fraction of a second until the server came back. The doubling now stops at 10 steps, so the wait is always between 3 s and 30 s.
- **Settings tree:** a robot, controller or camera whose fields have the wrong type (a number for a name, a text for a flag, an entry that is not an object) no longer throws a cast error from the model getters and takes the screen down; each field reads as its default and entries that are not objects are skipped.
- **HTTP answers:** a `200` whose body is JSON but not an object (a list, `null`, a number) is a `HydraApiException` instead of a cast error, a discovery answer whose `product`, `appVersion` or `hostname` is not text no longer breaks the scan, and a STOP answer with a count that is not a finite number (JSON `1e999`) keeps its robots instead of failing.
- Tests: 26 new (98 in all, line coverage of the app code up from 26 % to 35 %): tolerant readers, HTTP answers, STOP answer, back-off, frames of the wrong shape on the WebSocket, and the error texts in the 8 languages. The sign-out test no longer depends on how fast the first WebSocket close arrives.

## [0.2.4]

- Build version synchronized with `hydra-umc.project.json` and the repository-native version source.
- The licence is written as GPL-3.0-or-later in every header and in the package metadata.

## [0.2.3] - One-tap global STOP

- **Global STOP:** a big red **STOP** button at the right end of the top bar, on every tab, stops every robot of every controller with one tap: no long press and no confirmation. It calls `POST /api/stop-all` at once (bearer token and client header, no body), without waiting for any refresh, and works for an admin and an operator account. A robot reserved by another account is stopped too.
- **Screen-cleaning mode:** its one-tap STOP now makes the same global call, and the result (or the "not confirmed" warning) is shown inside the overlay.
- **Result robot by robot:** a banner under the top bar lists each robot (stopped or not, the reason, "reserved by ..." when someone else holds it), turns red with a warning when a robot failed or the server could not save the stop, and is closed by the user. The state is read again afterwards.
- **STOP that gets through:** a network error is retried once with a short timeout; a server over its rate limit (429) or without the route (404) is answered with the per-robot stop of every robot; when nothing answers, a persistent "STOP not confirmed" banner with a Retry button stays until a later STOP gets an answer.
- **Control tab:** the long-press E-STOP of the selected robot is replaced by a big one-tap global STOP; the round per-robot stop next to play/pause keeps its long-press protection.
- STOP, its descriptions and the result texts in the 8 languages; 8 new tests (72 in all) against a local server: the request, the per-robot answer, a failed/unsaved/reserved robot, the 429 and 404 fall back, the retry, the persistent state and the token renewal.

## [0.2.2] - Home pose no longer crashes the Control screen, session renewal, TLS servers, clear server refusals

- **The Control screen no longer disappears at the home pose:** the server writes whole numbers without decimals, so a joint at 0 arrived as an integer and `as double` threw, replacing the whole Control tab (STOP, jog, play) with Flutter's grey box. Joint angles are now read as numbers whatever their form, and an error outside the build pipeline reaches the screen (a snackbar, and a recovery screen with "copy error details") instead of only the log.
- **One renewal for one expired token:** the server's "Access denied" frame and the 1008 close that follows it are one event; they used to start two refreshes with the single-use refresh token, and the second one signed the panel out. Renewals are single-flight, an expired token found by a REST call or a command is renewed with the refresh token and the request repeated, and only a failed renewal signs out, completely (socket, polling, hydra-info poll, timers, stored session), instead of leaving them running behind the login screen.
- **TLS servers work:** the client learns whether the server answers https (login, settings and the scan resolve the scheme; the camera and the socket follow it) and remembers it, so a server started with `TLS_CERT_PATH`/`TLS_KEY_PATH` is no longer unreachable and is never probed over plain http again.
- **Clear refusals:** a robot reserved by another account (409), a command the server does not have (400), a missing permission (403) and a 200 answer with warnings each have their own message in the 8 languages, and the optimistic change is undone. Errors are detected by status and code, not by looking for "401" in a message.
- **Pause is explicit:** it is sent as `{paused: true|false}` computed once, so a combined pair cannot drift apart.
- **Jog that stops when released:** while one jog is on the wire the next tick of a held button is dropped instead of piling up behind a slow link, and nothing jogs while a trajectory is running.
- **STOP that gets through:** a stop is sent with 2 s timeouts and, when nobody answers, again up to 3 times; if it still fails the message says the STOP was not confirmed. The screen-cleaning mode now shows a one-tap STOP button on top of its touch-blocking layer.
- **Token out of the address:** the WebSocket sends the token as the `hydra.bearer` subprotocol (a server that refuses it gets `?token=` automatically), pings every 20 s to notice a dead link, reconnects with a growing back-off and ignores binary frames; every full snapshot is applied (the "same as the last one" filter hid changes made by deltas in between).
- **Camera:** the stream carries the bearer header, a non-200 answer is shown as such, the newest frame is the one drawn, the picture buffer is capped, the camera is chosen through `assignedRobotId`, and the Camera tab does nothing until it is shown.
- **Smaller fixes:** system metrics carry the bearer token and a host without a temperature sensor shows `--` instead of a made-up value, the Dashboard grid no longer rebuilds on every metrics tick, a relative XY-table jog no longer writes `pos.tx`/`pos.ty`, a login replaces the stored refresh token, the same error shown twice is shown twice, the scan finishes even if one host answers with something unexpected, the build scripts have a shebang and keep a single exit pause that asks only in a terminal, and the Windows build is credited to the project and its GPL-3.0 licence.
- **Docs:** the session token is documented as living in the platform's secure storage (on a panel without a keyring service the session lasts until the app restarts), `enable`/`disable` are gone from the docs, and the Portuguese README is linked from every language bar.
- 20 new tests (see `test/robot_view_model_server_errors_test.dart`, `test/hydra_websocket_token_test.dart` and `test/session_storage_test.dart`).

## [0.2.1] - Portuguese interface and README, translation parity tests

- **Portuguese interface:** the app is now available in Portuguese (`lib/l10n/app_pt.arb`, all 82 strings), selectable in `Settings > Language` and picked automatically when the system locale is Portuguese; the interface now covers 8 languages and a README in Portuguese (`README_por.md`) joins the other translations.
- **Translation tests:** the localization tests now check that Portuguese resolves and that every language file defines exactly the same keys and placeholders as the English one, so a missing or misspelled placeholder fails the test instead of showing up on the panel (44 tests).

## [0.2.0] - Reconnect delivery test coverage, narrowed Dashboard rebuilds

- **Reconnect test coverage:** the existing WS reconnect test proved a
  second real connection was accepted after an abrupt drop, but never
  proved data delivery actually resumed on it. Added a test that sends a
  real settings payload on the first socket, forces a drop, then sends a
  new real payload on the reconnected socket and asserts both are
  delivered in order.
- **Dashboard rebuild scope:** `DashboardScreen` used one
  `context.watch<RobotViewModel>()` at its root, so any change on the
  shared view model (a metrics tick every 5s, a robot's live telemetry,
  a WS status change) rebuilt the metrics bar AND every robot card in
  the grid together. Split into independently-`Selector`ed widgets for
  the metrics bar and the robot grid, and wrapped each robot card in its
  own `RepaintBoundary`, so an update to one side no longer rebuilds or
  repaints the other.

## [0.1.9] - Honesty check section in every README

Added a "Honesty check" paragraph right after the intro badges in
`README.md` and all 6 translated READMEs, naming the real, tested
networking/state modules (`hydra_api_client.dart`,
`hydra_websocket.dart`, `discovery.dart`, `auth_prefs.dart`,
`robot_view_model.dart`, `hydra_error.dart`) and the real test count
(41 passing across `test/*.dart`; `flutter analyze` clean). States
plainly that the 3D View screen is a native isometric indicator, not a
real 3D renderer, and that `flutter build linux` has only ever been
verified under WSL2 (x86_64), never on the CM5's real aarch64
hardware, with the `kiosk/hydra-umc-dsi.service` autostart unit still
completely unverified. Also fixed a stale `test/` directory-listing
comment that was missing 3 real test files
(`robot_view_model_silent_refresh_test.dart`, `auth_prefs_test.dart`,
`hydra_websocket_test.dart`). Documents the real, current state of
what's implemented vs. planned; no behavior changed.

## [0.1.8] - Real coverage for cancelling an in-flight robot order

Found while re-checking test coverage after every existing
`_sendAtomicCommand` test started from an idle robot - none exercised the
real "cancel an order actually in flight" case, untested in every client
except the internal voice relay. The same real gap was closed in
HYDRA-UMC-ANDROID-CONTROL's own
`RobotViewModelSendAtomicCommandTest.kt`. 2 new tests: cancelling an
in-flight order optimistically stops both the target robot and its
`combinedWith` sibling immediately, and a failed cancel rolls both back
to still-playing.

## [0.1.7] - silent recovery from a WS 1008 close via a real refresh token

Follow-up to 0.1.6: stopping the retry loop and surfacing `wsAuthRejected`
was correct, but still forced a real logout on the single most common
real cause of a 1008 - the access token's own real time-based expiry, not
an actual account revocation. This app never stores a password (unlike
HYDRA-UMC-ANDROID-CONTROL's own "remember me", which does), so recovery
here mirrors HYDRA-UMC-STUDIO's own client instead: `HydraApiClient`
gains `refresh()`/`logoutRemote()` against HYDRA-UMC-SERVER's own new
`POST /api/refresh`/`POST /api/logout` (HYDRA-UMC-SERVER 0.6.2);
`AuthPrefs` stores the real opaque refresh token `POST /api/login` now
also returns, through the same secure-storage-only policy (never a
plaintext fallback) `hydra_token`/`hydra_username` already use.
`RobotViewModel._attemptTokenRefresh()` tries this before falling through
to today's forced logout - which still happens exactly when it should
(no refresh token on file, a genuinely revoked session, or a server
predating this feature). `RobotViewModel` gained an optional injectable
`authPrefs` constructor parameter (same DI pattern `HydraApiClient`/
`AuthPrefs` themselves already use) specifically so this whole
login->1008->refresh->reconnect lifecycle could get real end-to-end test
coverage against a real local HTTP+WebSocket server, not just the
storage layer in isolation. `flutter analyze`/`flutter test` both clean;
39 tests (8 new).

## [0.1.6] - A rejected session token no longer retries forever, silently

`network/hydra_websocket.dart`'s own header comment already claimed a
1008 close was "treated as sign in again" - it wasn't; `onDone` always
rescheduled a reconnect, unconditionally. Real gap: server.ts closes the `/ws` upgrade with RFC 6455 code 1008
for a missing/invalid/expired token and never sends a message frame
first, so the existing `{"error": "..."}` check could never catch this
case - the app just spun forever in "connecting" -> "disconnected" with
no visible error. Now checks the real close code and, on a 1008, stops
retrying and surfaces a new, localized `wsAuthRejected` error (all 7
languages) that `RobotViewModel` treats as a forced logout, same as a
server-relayed "denied"/"token" message. Same fix ported from
HYDRA-UMC-IOS-CONTROL's own copy of this file. Real end-to-end
regression test against a real local WebSocket server
(`test/hydra_websocket_test.dart`).

## [0.1.5] - a failed logout or a half-written session could resurrect an old token

A second review pass found two real gaps by static
inspection of `AuthPrefs` (`network/auth_prefs.dart`): `clearToken()`
caught a failed secure-storage `delete()` and only logged it, so a real
logout could return successfully while the old token was still sitting
in secure storage - a later `loadToken()` (a real restart, say) could
resurrect the "cleared" session. Separately, `saveToken()` wrote the
token and username as two separate secure-storage calls; if the token
write succeeded but the username write then failed, the catch block
reported the whole session as in-memory-only while secure storage was
actually left holding a real, orphaned token with no matching username.

Fixed with a plain, non-secret `hydra_logged_out` marker in ordinary
SharedPreferences - the real, persistent source of truth `loadToken()`/
`loadUsername()` now check FIRST, set BEFORE `clearToken()` ever
attempts the real secure delete (so a failed delete can never
un-invalidate a real logout), and cleared only by a fresh, successful
`saveToken()`. `saveToken()` itself now reverts (best-effort) whatever
it did manage to write if a later step in the same call fails, so
secure storage never holds half of a session. Same real fix ported to
HYDRA-UMC-IOS-CONTROL's own `AuthPrefs`.

## [0.1.4] - real regression found by independent revalidation

A second review pass reproduced a real gap in v0.1.3's own
fix (against a real fake `SecureTokenBackend`, no real platform
channel):

- `saveToken()` wrapped every secure-storage write so a
  failure fell back to writing the token in PLAIN `SharedPreferences` -
  exactly the failure of the protection mechanism itself silently
  removing the guarantee was meant to provide. A UI-level
  biometric/lock-screen gate would still do nothing to protect that
  plaintext copy underneath it. Fixed: a secure-storage write failure now
  keeps the session in memory ONLY, for the current app run - never
  written to disk in plaintext. A real restart/power-cycle on a device
  whose secure storage is genuinely broken now requires logging in
  again, rather than the token quietly living in a plaintext file. Never
  regresses a device where secure storage genuinely works (this app's
  real, intended kiosk deployment target). A earlier legacy plaintext
  token is still migrated in and read normally - that is reading
  pre-existing data, not a new plaintext write.
- 2 new regression tests (one asserting the plaintext file is never
  touched, one proving a fresh app instance genuinely cannot recover an
  in-memory-only session - the real, deliberate trade-off this fix
  makes); the 2 existing tests that used to assert the old plaintext
  fallback as correct behavior were rewritten to assert the fix instead.
  `flutter analyze`/`flutter test` both clean.

## [0.1.3] - real secure storage for the session token

- 
  the session token lived in the same plain `SharedPreferences` file as
  host/port - not a secrets vault, and a UI-level biometric/lock-screen
  gate (if this kiosk ever grows one) would not protect the persistent
  copy underneath it. `network/auth_prefs.dart` now reads/writes the
  token through a new `SecureTokenBackend`, backed by
  `flutter_secure_storage` (libsecret's Secret Service on Linux - this
  app's real deployment target). A bare kiosk image may not run a Secret
  Service provider at all, so every secure call is wrapped: on any
  failure it falls back to the exact same `SharedPreferences`-backed
  behavior this file had before this fix, logging a clear, token-free
  warning instead of silently losing a real session. A token saved under
  the old plain key is migrated into secure storage (and the old copy
  removed) the first time it is read back. 7 new tests
  (`test/auth_prefs_test.dart`) cover the real round trip, the migration,
  and the no-regression fallback path, all against a fake backend (no
  real platform channel). Not yet verified against a real Secret Service
  provider on the actual CM5 kiosk image - that remains real, tracked
  future verification.
- removed the 6 remaining references to private
  internal planning documents across
  `CHANGELOG.md`, `docs/ARCHITECTURE.md`, `network/discovery.dart`,
  `test/robot_view_model_test.dart` and `tool/bump_version.dart` - the
  reasoning each one supported is now stated in place instead of pointing
  at a document outside this repository.
- **New `test/hydra_websocket_test.dart`** (5 tests) - found while
  hardening this: `network/hydra_websocket.dart`
  (175 lines, real Timer-based reconnection) had no dedicated test - this
  app's other tests (uptime formatting, localization, the view model)
  never touch reconnection state. Real end-to-end tests against a real
  local `dart:io` WebSocket server (`HttpServer` + `WebSocketTransformer`),
  not a mock - `WebSocketChannel.connect()` is a real `dart:io` socket
  under the hood on this platform, so a real local server is what
  actually exercises the real `onDone`/`onError`/`_scheduleReconnect`
  logic. Covers: the real handshake gating `WsStatus.connected`, a real
  settings payload delivered end to end, automatic reconnection after a
  real connection drop, `disconnect()` cancelling a pending reconnect for
  good, and the real error reported when nothing is listening (found
  live: `web_socket_channel`'s own stream can report a refused connection
  via `onError` before `HydraWebSocket`'s own `await channel.ready` gets
  a chance to throw - both are the same real outcome from a caller's own
  point of view, so the test accepts either).

## [0.1.2]

- **Verified the `build.sh`/`build_linux.sh` exit-trap fix from 0.1.1 with
  a real re-run**: `build_linux.sh` invoked again end to end, non-
  interactively (closed stdin), now correctly reports exit code 0 for a
  genuinely successful build instead of the stale exit code 1 the
  unfixed trap used to report.

## [0.1.1]

- **First real `flutter build linux` verification** - until now, only
  `flutter build windows` had ever actually been run against this code (no
  Linux build toolchain was available in the original working
  environment). A real Ubuntu 24.04 WSL2 environment with the full Linux
  desktop toolchain (`cmake`, `ninja-build`, `libgtk-3-dev`, `clang`) now
  runs `build_linux.sh` end to end and produces a genuine
  `build/linux/x64/release/bundle/hydra_umc_dsi` - confirmed to actually
  launch (not just compile: it stayed running under a real X11 display,
  not just a passing exit code). The real CM5's aarch64 hardware itself,
  and the `kiosk/hydra-umc-dsi.service` autostart flow, remain unverified
  - see README.md's "Known Follow-ups".
- Fixed `build.sh`/`build_linux.sh`'s own exit-trap: under `set -e`, the
  final "press any key to close" `read` failed (and was mistaken for a
  build failure, exit code 1) whenever either script ran without an
  interactive terminal attached (stdin closed, as in CI or a piped
  invocation) - it now tolerates that case instead of masking a real
  build success as a failure.

## [0.1.0]

- **Full 7-language UI localization** - this app had no `intl`/
  `flutter_localizations` at all before this release; every screen showed
  hardcoded English regardless of device locale, unlike the rest of the
  ecosystem's UIs. Added the standard `flutter gen-l10n` pipeline
  (`lib/l10n/app_*.arb`, one real translation per key - Spanish, French,
  German, Italian, Japanese, Chinese, no placeholders) covering every
  screen's chrome including the screen-cleaning-mode overlay and the
  dedicated Metrics screen, plus a persisted language override
  (`Settings > Language`, `LanguagePrefs` via `shared_preferences`) that
  defaults to the OS locale when unset.
- **Business-logic error messages now localizable too**: `RobotViewModel.
  lastError` was a raw English `String` built inside a `ChangeNotifier`
  with no `BuildContext` to localize from. Replaced with a typed
  `HydraError` (kind + raw parameters, never pre-formatted text), same
  seam HYDRA-UMC-IOS-CONTROL's own 0.0.9 release introduced - the UI layer
  resolves it via `AppLocalizations` only when it actually renders a
  message, and a server-relayed WS error message is correctly left
  untouched (already resolved server-side).
- **Human-readable uptime on the Dashboard** (`ui/dashboard_screen.dart`'s
  new `formatUptime()`) - was a raw hours-with-one-decimal figure, now the
  same "2d 4h 15m" format `ui/metrics_screen.dart`'s own dedicated Metrics
  screen already used, fixing an inconsistency within this same app.
- Real test coverage: `test/localization_test.dart` builds an actual
  widget tree under `Locale('es')`/`Locale('ja')` and asserts on resolved
  strings and interpolated placeholders; `test/format_uptime_test.dart`
  covers the minutes-only/hours-and-minutes/days-hours-minutes/zero-day-
  boundary cases. `flutter analyze`: 0 issues. `flutter test`: all
  passing.

## [0.0.9] - Debounced the speed/acceleration slider's real network send

- **`lib/state/robot_view_model.dart`** - `setSpeed()` now debounces its
  real `POST /api/robot/:id/command` send by 300ms, matching
  HYDRA-UMC-ANDROID-CONTROL's own `sendAtomicCommand(..., debounceMs =
  300)` and the same real fix just applied to HYDRA-UMC-IOS-CONTROL
  (this repo's own upstream port source - the omission propagated here
  too). Every drag frame of the speed/acceleration `Slider`
  (`ui/control_screen.dart`) used to fire its own real network request -
  the local optimistic UI update still applies instantly every frame
  (unchanged), only the actual round-trip is now coalesced into one real
  send once the drag settles, cancelling any still-pending send for the
  same command name (`_sendAtomicCommand`'s new `debounce` parameter,
  backed by a per-command `Timer` map). Every other real-time control
  (jog, E-STOP/play/pause/stop, valve/pump toggles) already sent
  immediately and is unaffected.

## [0.0.8] - Fixed a real version-drift bug in build.bat's own step order

- **`build.bat`** - it ran `bump_manifest_version.py` (a real, independent
  bump) *before* `dart run tool/bump_version.dart`, the real source of
  the app's own native version (`pubspec.yaml`). That let the manifest
  advance to a version the compiled app hadn't reached yet - exactly the
  drift class this ecosystem's version-mirror convention exists to
  prevent. `build.sh`/`build_linux.sh` already had the correct order;
  `build.bat` now matches: `dart run tool/bump_version.dart` first, then
  `bump_manifest_version.py --sync` to align the manifest to what the
  app build actually produced. Verified with a real `flutter build
  windows` run through the fixed script.

## [0.0.7] - Removed the hardcoded admin/admin credential default

- **`server_info.dart`/`login_screen.dart`** - the login screen no longer
  pre-fills `admin`/`admin`. Every real HYDRA-UMC-SERVER now refuses to
  seed that source-known default account on a real production first
  start (see that repo's own changelog: production requires explicit
  `HYDRA_UMC_BOOTSTRAP_ADMIN_USERNAME`/`_PASSWORD`) - pre-filling a
  credential that no longer exists on a real deployment was actively
  misleading, not a convenience. `_submit()` now also refuses to send an
  empty username or password rather than letting an empty field reach
  the server as a real login attempt.
- `SECURITY.md` documents the real expectation: the kiosk never carries
  a built-in credential: the operator enters what the server bootstrap
  process actually issued, and should clear it before the display
  changes hands.
- Verified: `flutter analyze` clean, `flutter test` 6/6 passing.

## [0.0.6] - Removed dead enable/disable command plumbing

- Found on code review: `state/robot_view_model.dart`'s
  `sendCommand()` had `'enable'`/`'disable'` cases that POSTed
  `command: "enable"`/`"disable"` to `/api/robot/:id/command` and
  optimistically flipped the robot `online` flag locally via
  `RobotView.setOnline()`. HYDRA-UMC-SERVER's real handler for that
  endpoint has no `"enable"`/`"disable"` case in its command `switch` -
  only `stop`/`play`/`pause`/`jog`/`tool`/`valve`/`pump`/`speed`/`vision`
  - and always responds `{ success: true }` regardless of whether any
  case matched, so either command would have silently done nothing
  server-side (no state change, no broadcast to other clients) while
  this app's own screen flipped online/offline as if it had worked.
  `control_screen.dart` never called `sendCommand('enable'/'disable')`
  and grep found no other call site, so the cases were dead, unreachable
  code - but they were a real trap for whoever wired a future
  online/offline button to it. Removed both cases from `sendCommand()`
  and the now-unused `RobotView.setOnline()` helper it was the only
  caller of; `robot_view_model_test.dart`'s optimistic-mutation/rollback/
  combinedWith-propagation coverage now exercises the same
  `_sendAtomicCommand()` machinery through `sendCommand('play')` instead,
  a real command the server and `control_screen.dart` both already
  support. A real online/offline toggle, if ever needed, would require
  adding a matching case to HYDRA-UMC-SERVER's own command handler first
  - out of scope here.

## [0.0.5]

- Build version synchronized with `hydra-umc.project.json` and the repository-native version source.

## [0.0.5+6] - Adaptive backlight by time of day

- New `services/backlight.dart` - writes to Linux's own
  `/sys/class/backlight/*/brightness` (globbed rather than a hardcoded
  device name, since the real driver directory depends on which panel/
  bridge chip the actual board uses), scaled against that device's own
  `max_brightness` rather than a fixed 0-255 assumption. A fixed
  day/evening/night schedule (100% / 60% / 30%) is checked once at
  startup and every 15 minutes in `MainScreen`. Every failure path
  (no `/sys/class/backlight` at all, no device registered, an
  unwritable file) degrades to a no-op rather than a crash - this is a
  cosmetic feature, not something that should ever take the kiosk app
  down.
- NOT verified against a real DSI panel (no CM5 available this
  session) - the schedule math and the defensive non-Linux no-op path
  were both verified with a real `dart run` (all boundary hours check
  out, `setBrightnessPercent()` correctly returns `false` without
  throwing on this Windows dev machine). `flutter analyze` clean, real
  `flutter build windows` succeeded.

## [0.0.4+5] - Screen-cleaning mode

- New cleaning-services icon button in the top nav bar - locks touch
  input for 30s (a real `AbsorbPointer` overlay, not just a visual dim)
  so an operator wiping the panel down mid-shift can't accidentally jog
  a robot or hit E-STOP through the cloth. Auto-dismisses when the
  countdown reaches zero; a long-press on the overlay itself ends it
  early (a stray accidental tap during cleaning must not dismiss it, so
  a deliberate long-press is required, not a plain tap).
- Verified with `flutter analyze` (no issues) and a real `flutter build
  windows` (dev-machine verification target per this project's own
  `build.bat` - the real CM5/Linux target needs `build_linux.sh` run on
  actual Linux hardware).

## Earlier history

### 0.0.0+1 and prior (pre-versioning-policy history)

- **Initial commission** - Commissioned alongside HYDRA-UMC-EDITOR-URDF;
  full spec received in the same message. Stack decision (Flutter vs.
  Python/Kivy) deliberately left open until implementation start.
- **Hardware spec correction** - The real DSI panel resolution is
  1280x720 (not 1280x800 as originally documented), identical at both the
  5" and 7" physical sizes - one fixed layout serves both, no breakpoints
  needed. Corrected across this project's own docs and the "Related
  Projects" block of all 10 sibling repos (5 languages each).
- **Initial implementation** - Repo actually created from scratch
  (`flutter create --platforms=linux,windows`, Flutter SDK 3.47.0).
  Stack decision made: **Flutter**, reusing HYDRA-UMC-IOS-CONTROL's
  already-written Dart REMOTE_API.md client, state model, and several UI
  widgets directly (same language, same framework) - a Kivy/Python stack
  would have meant rewriting all of that from scratch with no ecosystem
  precedent. (Found and corrected a stale claim along the way: contrary to
  what the original commission said, HYDRA-UMC-IOS-CONTROL never actually
  had a `linux/` folder - its real target is iOS, Windows only for
  Mac-less verification. HYDRA-UMC-DSI is the ecosystem's first Flutter
  app with a real `linux/` target.) All 6 catalog screens implemented and
  wired to the real REMOTE_API.md contract: login, dashboard, manual
  control (real long-press E-STOP/STOP protection), camera (hand-rolled
  dependency-free MJPEG parser, ported), 3D view (deliberately a native
  isometric X/Y/Z `CustomPainter` indicator, NOT a WebView - no Linux
  desktop `webview_flutter` implementation exists, and a full browser
  engine is too heavy for this embedded panel), and metrics (new
  dedicated tab, unlike iOS/Android which fold it into the Dashboard).
  `X-Hydra-Client: dsi` sent (new value, not yet server-recognized for
  per-client remote-access gating - out of scope, needs a STUDIO-side
  change). Verified for real: `flutter analyze` clean, `flutter build
  windows` produced a running `.exe`, `flutter test` passed 1 smoke test.
  `flutter build linux` (the real target) honestly documented as
  unverifiable from this Windows machine (no WSL distro installed).
  Full documentation pass: README.md + 4 translations, LICENSE,
  `docs/ARCHITECTURE.md`, all build/run scripts. Ecosystem-wide: the other
  10 project READMEs (5 languages each, 50 files) updated from
  "planned/not started yet" to this repo's real scaffolded state, and the
  stale 1280x800 resolution fixed wherever it still lingered
  (URTC-FLASHER, URTC, HYDRA-UMC).
- **Second pass** - a critical review of what was actually actionable
  without real hardware. 2 items resolved:
  - **Real mDNS discovery** ported directly from HYDRA-UMC-IOS-CONTROL's
    own `network/discovery.dart` (`multicast_dns` package, same version),
    with an honest header noting the iOS-only Apple entitlement caveat
    doesn't apply here, but real-Linux-hardware verification still does.
    `login_screen.dart`'s "Scan local network" dialog now runs mDNS and
    subnet scan in parallel, deduplicated.
  - **Kiosk autostart** on the CM5 (`kiosk/hydra-umc-dsi.service`,
    `kiosk/install_kiosk.sh`) - a systemd unit launching the build via
    [`cage`](https://github.com/cage-kiosk/cage) fullscreen on `tty1`,
    `Restart=always`. Chosen over `flutter-pi` because it reuses
    `build_linux.sh`'s own output unmodified. Runs as root deliberately
    (documented), never tested against real hardware (documented).
  1 item reduced in scope (not eliminated): `robot_view_model_test.dart`
  added (5 tests: atomic-command rollback, optimistic mutation,
  `combinedWith` propagation, `lastError` clearing) using `http`'s
  `MockClient` - no widget-level tests added, matching iOS-Control's own
  current coverage.
  3 items evaluated and deliberately left alone: the `dsi` client-type
  server-side gate (needs a STUDIO change, out of scope), a more complete
  native 3D view (no mature precedent to port from, and inventing one
  fresh would go against this project's own "reuse, don't invent" rule),
  and encrypted credential storage via `flutter_secure_storage` (Linux
  backend needs a D-Bus secret-service session a minimal `cage` kiosk very
  plausibly won't have running - risk of a silently broken save/load on
  real hardware that can't be checked from this machine, so documented
  instead of implemented blind). Reverified: `flutter pub get`, `flutter
  analyze` clean, `flutter test` 6/6 passing, `flutter build windows`
  succeeding. `flutter build linux` still unverifiable from this machine.
