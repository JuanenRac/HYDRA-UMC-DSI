# Changelog

All notable changes to HYDRA-UMC DSI are summarized here. Full
session-by-session detail (including dates) lives in the private,
unpublished `SONNET/HYDRA-UMC-DSI/auditoria_historial.txt`.

Version numbers below follow the ecosystem-wide auto-bump policy described
in [README.md](README.md#-versioning); earlier entries are grouped under
the pre-policy version `1.0.0+1` the repo carried while the policy did not
yet exist.

## [Unreleased policy]

- **Automatic version bump on every real build.** `build.sh`/`build.bat`/
  `build_linux.sh` now run `tool/bump_version.dart` before `flutter
  build`, which bumps `pubspec.yaml`'s `version:` line on every
  invocation: patch +1, with an odometer-style carry into minor once
  patch would exceed 9 (`1.0.9` -> `1.1.0`), and a plain monotonic
  build-number (+1, no carry). No manual version editing from here on.
  Ported directly from HYDRA-UMC-IOS-CONTROL's own `tool/bump_version.dart`
  (implemented in parallel against the same owner directive) - same rule,
  same generated-file shape.
- `lib/app_version.dart` (generated, not hand-edited) now exposes
  `kAppVersion`/`kAppBuildNumber`/`kAppVersionFull` at runtime, regenerated
  by the same script - avoids adding `package_info_plus` as a new runtime
  dependency (and its unverifiable-on-the-real-CM5 native Linux behavior)
  just to show the version in the UI.
- Settings screen (`lib/ui/settings_screen.dart`) now shows the running
  app's own version and build number, in a tile clearly labeled "HYDRA-UMC
  DSI version" so it isn't confused with the pre-existing "App version"
  tile just above it, which reports the *connected server's* own version
  from `hydraInfo`.
- All 3 build scripts (`build.bat`, `build.sh`, `build_linux.sh`) now
  print a visible banner (project name, what the script does, author,
  license) via real `echo` output at launch, and pause with a keypress
  prompt at the end - on both success and failure - so a double-clicked
  script window doesn't close before its output can be read.
- This file added, seeded from the real project history below.

## 1.0.0+1 and prior (pre-versioning-policy history)

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
- **Second pass** - Owner asked for a critical pass over
  `mejoras_futuras.txt` to resolve what was actually actionable without
  real hardware. 2 items resolved and removed:
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
