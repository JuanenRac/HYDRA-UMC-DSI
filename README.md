<!-- =============================================================================
HYDRA-UMC-DSI - Native touch UI for the CM5 DSI screen
Copyright (C) JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
GPL-3.0-or-later - see LICENSE
============================================================================= -->

<p align="center">
  <img src="images/HYDRA_UMC_BANNER.svg" alt="HYDRA-UMC-DSI banner" width="100%">
</p>

# 🖥️ HYDRA-UMC-DSI

<p align="center">🇺🇸 <b>English</b> | <a href="README_spa.md">🇪🇸 Español</a> | <a href="README_fra.md">🇫🇷 Français</a> | <a href="README_ita.md">🇮🇹 Italiano</a> | <a href="README_deu.md">🇩🇪 Deutsch</a> | <a href="README_zho.md">🇨🇳 简体中文</a> | <a href="README_jpn.md">🇯🇵 日本語</a> | <a href="README_por.md">🇵🇹 Português</a></p>

### A native touch interface for the Compute Module 5 DSI screen

<p align="center">
  <img src="https://img.shields.io/badge/License-GPL%203.0--or--later-blue.svg" alt="GPL 3.0 or later">
  <img src="https://img.shields.io/badge/Framework-Flutter%203.x-02569B.svg" alt="Framework">
  <img src="https://img.shields.io/badge/Language-Dart-0175C2.svg" alt="Language">
  <img src="https://img.shields.io/badge/Platform-Linux%20%7C%20CM5-E34F26.svg" alt="Platform">
  <img src="https://img.shields.io/badge/Tests-174%20passing-2ea44f.svg" alt="Tests">
  <img src="https://img.shields.io/badge/Version-0.2.7-0f6cbd.svg" alt="Version">
  <img src="https://img.shields.io/badge/Maturity-functional-0F6CBD.svg" alt="Maturity">
</p>

---

A native Flutter touch UI (Dart, real Linux desktop target) for HYDRA-UMC's own 5"/7" DSI touchscreen on the Compute Module 5 - both physical panel sizes share the exact same 1280x720 pixel resolution, so this app ships one fixed, non-responsive layout instead of adapting to two sizes. It speaks the exact same [`REMOTE_API.md`](https://github.com/JuanenRac/HYDRA-UMC-SERVER/blob/main/docs/REMOTE_API.md) contract [HYDRA-UMC SUITE](https://github.com/JuanenRac/HYDRA-UMC-SUITE), [HYDRA-UMC-ANDROID-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-ANDROID-CONTROL), and [HYDRA-UMC-IOS-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-IOS-CONTROL) use - discovery, login, atomic per-robot commands, and live WebSocket sync against a running [HYDRA-UMC-SERVER](https://github.com/JuanenRac/HYDRA-UMC-SERVER), run directly on the board itself rather than over a browser tab. See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for the full design, including why Flutter (not Kivy) and why the 3D screen isn't a WebView.

**This app is one of two coexisting control surfaces on the same board** - the CM5 also drives an HDMI output for a full external monitor running the browser UI. This DSI app complements that path with a direct, always-on touch console at the board itself; it does not replace the browser UI.

---

**Honesty check - what actually runs today:** the networking layer (`lib/network/hydra_api_client.dart`, `hydra_websocket.dart`, `discovery.dart`, `auth_prefs.dart`) and the state layer (`lib/state/robot_view_model.dart`, `hydra_error.dart`) are real and tested (174 tests passing across `test/*.dart`, including a real WebSocket connect/reconnect/auth-rejection round trip against a genuine local server, not a mock), and `flutter analyze` reports no issues. All 6 catalog screens are real, wired UI, not placeholders. What is genuinely not built: the **3D View** screen is a small native isometric X/Y/Z indicator, not a real 3D renderer - it does not embed STUDIO's Three.js scene (no Linux `webview_flutter` implementation exists). What is real but unverified on target hardware: `flutter build linux --release` has been run and produces a binary confirmed to launch, but only under Ubuntu 24.04 WSL2 (x86_64) - never on the CM5's real aarch64 Raspberry Pi OS - and the `kiosk/hydra-umc-dsi.service` autostart unit has never run on any real Linux machine at all. See "Known Follow-ups" below and `CHANGELOG.md` for exactly what has shipped so far.

> **Safety and security status:** this ecosystem is not a certified safety system. There is no hardware E-STOP path, no firmware-enforced limits or interlocks and no verified motion command yet; firmware images are checked with CRC-32 and an Ed25519 signature, and a release build refuses the published development keys (the tool heads and expansion boards behind the relay still run URTC bootloaders, which take a shared-key HMAC-SHA256 instead of a signature); TLS and mutual TLS are optional and off by default; no custom board has been populated or tested yet. Read the [security baseline](https://github.com/JuanenRac/HYDRA-UMC-DOCS/blob/main/docs/SECURITY_BASELINE.md) and the [threat model](https://github.com/JuanenRac/HYDRA-UMC-DOCS/blob/main/docs/THREAT_MODEL.md) before relying on any statement here for the safety of a person.

---

## 📋 At a glance

| | |
|---|---|
| Version | `0.2.7` |
| Maturity | Functional |
| Tests | 174 (`flutter test`) |
| Stack | Flutter 3.x / Dart |
| Target | The Raspberry Pi CM5 of a HYDRA-UMC cell |
| On real hardware | Not yet: no run on real hardware is recorded for this version |

**Jump to:** [Overview](#-overview) · [Architecture](#-architecture) · [Quick start](#-quick-start) · [Testing](#-testing) · [Repository Structure](#-repository-structure) · [Related Projects](#-related-projects)

## 🚦 Project status

Each line is one part of this repository and the light says how far it is today. It is written from what the repository can show (tests, builds, runs), not from what is planned.

🟢 Done and verified · 🟡 Works, with known limits · 🟠 Partly done or not verified yet · 🔴 Not done or not working

| Area | State | What it means here |
|---|---|---|
| Software | 🟡 | Works for its main purpose; the honesty check above lists what is still missing |
| Tests | 🟢 | 174 automated tests, run on every change |
| Real hardware | 🔴 | Not yet: no run on real hardware is recorded for this version |
| Documentation | 🟢 | README in eight languages, checked against the manifest on every change |

## 🎯 Overview

- **Login** (`lib/ui/login_screen.dart`, `lib/state/robot_view_model.dart`) - server IP/port fields pre-filled with a sane LAN default, username/password fields sized for touch and left blank by default (no hardcoded credential is pre-filled - the initial `admin`/`admin` pre-fill was removed once every server started refusing to seed that default account on a real production first start), `POST /api/login` against whatever account the operator enters; additional lower-privilege "operator" accounts can be created from Config > Users in the browser UI. The session token is kept in the platform's secure storage (libsecret on Linux, which needs a running keyring service: on a panel without one the session lasts until the app restarts and the login is asked again). A "Scan local network" dialog (`lib/network/discovery.dart`) finds servers without needing to already know the IP - doubly useful here, since the CM5 this app runs on is often the very controller it should connect to.
- **Network discovery** (`lib/network/discovery.dart`) - two paths run in parallel from the same "Scan local network" dialog: real mDNS/Bonjour (`discoverMdns()`, querying `server.ts`'s own `_hydra._tcp` publish via the `multicast_dns` package) and a concurrent brute-force scan of `GET /api/hydra-info` across this device's own real local subnet(s) (`scanSubnets()`), deduplicated by host:port - ported from HYDRA-UMC-IOS-CONTROL, the first client in this ecosystem to add real mDNS discovery.
- **Atomic command sync** (`lib/state/robot_view_model.dart`'s own `_sendAtomicCommand()`) - every write (play/pause/stop/jog/valve/pump/speed/vision) uses the real `POST /api/robot/:id/command` endpoint, with correct combined-robot (`combinedWith`) propagation and a rollback to the pre-mutation snapshot if the request fails - especially important for a jog pendant/E-STOP a few feet from the actual robots.
- **Live WebSocket sync** (`lib/network/hydra_websocket.dart`) - sends the token as the `hydra.bearer` subprotocol and never in the address, handles both `"settings"` and `"delta"` broadcast types, auto-reconnects on drop.
- **Horizontal touch navigation** (`lib/ui/main_screen.dart`) - a persistent top bar of 6 large icon+label tabs (Dashboard/Control/Camera/3D View/Metrics/Settings) across the fixed 1280px width, KlipperScreen-in-spirit rather than a phone-style bottom nav bar - matching the catalog the project owner asked for, reorganized for a wide touch panel instead of a vertical phone layout.
- **Dashboard** (`lib/ui/dashboard_screen.dart`) - per-robot cards, reactive in real time via `Provider`, LED convention (green pulsing = active, red solid = inactive), combined-robot display, and module chips (CAM/XY/ATC/PNP/CNC/LSR/BED/VAC/RCK) - same visual language as every other client in this ecosystem.
- **Manual Control** (`lib/ui/control_screen.dart`, `lib/ui/widgets/joystick_pad.dart`) - side-by-side layout (jog pad left, telemetry/speed/IO right) sized for the 1280x720 frame instead of a single scrolling column, the global **STOP** (`lib/ui/widgets/stop_all.dart`) in the top bar of every tab, also on the Control tab and in the screen-cleaning overlay: one tap, no long press and no confirmation, it stops every robot (`POST /api/stop-all`), shows the result robot by robot (a warning when a robot failed or the stop was not saved, robots reserved by someone else marked), retries once on a network error, falls back to the per-robot stop on a 429 or with an older server, and keeps a persistent "STOP not confirmed" banner until a later STOP is answered (the round per-robot stop keeps its long-press protection), speed/acceleration sliders, valve/pump toggles.
- **Reservations and safety limits** (`lib/ui/widgets/access_panel.dart`, `lib/models/access.dart`, `lib/network/hydra_api_client.dart`, `lib/state/robot_view_model.dart`) - The Control screen shows who holds the selected robot (nobody, this device, the same account on another device, or another account) and offers **Reserve** and **Release**, plus the list of every reservation of the server (`GET /api/claims`). The device keeps one controller id for the installation and sends it with every reserve, release, jog-arm and command (body and `X-Controller-Id` header), so a reservation belongs to the account and to this device, not to the whole account. The refusals of the server are told apart: reserved by another account, by your account on another device or window, controller id required, and jog not armed. The limits of the robot's model are read from `GET /api/safety-limits`: a jog step above the limit is not sent, and the server's warnings are shown. When the administrator requires it, an **Arm jog** button (with a countdown) must be pressed before the joystick moves the robot; the arming ends by itself, with STOP, or on release. Reservations are optional: a robot nobody reserved is commanded as before. For an **administrator** only, a **Take control** button appears on a robot someone else holds; it asks for confirmation and then reserves the robot with `force: true` (the server accepts that from administrators only and checks the role again). Writes are conditional: each one carries the revision of the robot this app last saw (`If-Match`, `lib/models/contract_v2.dart`), and when someone else changed the robot in between the server answers 412, nothing is applied, the robot is read again and the message says so (Standard checks reservations, the table and one-off commands; Strict checks everything but STOP; Off checks nothing; the choice is in the list of reservations; STOP is never checked). The XY table jog is one atomic `table` command (an older server gets the jogs it understands), the server pushes the reservations over the WebSocket so the Control screen stops polling while they arrive, and administrators read the audit record (`lib/ui/widgets/audit_dialog.dart`) with its SHA-256 chain verified twice, by the server and on the computer, and can copy its lines as `.jsonl`.
- **Ask before PLAY** - on by default, turned off in Settings: before a trajectory starts the app shows the robot, its recorded points, the speed and who has it reserved (a robot reserved by someone else says the server will refuse the command). A robot that is already playing is not asked again. The choice is kept.
- **Camera** (`lib/ui/camera_screen.dart`, `lib/ui/widgets/mjpeg_view.dart`) - the same hand-rolled, dependency-free MJPEG stream parser as HYDRA-UMC-IOS-CONTROL (no WebView, no platform-specific code - it just works on Linux desktop unmodified), a clear "Camera Disabled" state, and a switch to turn a robot's vision system on/off directly from the server.
- **3D View** (`lib/ui/three_d_screen.dart`) - **not** a WebView embed of STUDIO's real Three.js scene, unlike the iOS/Android apps - `webview_flutter` has no Linux desktop implementation at all, and a full browser engine is a heavier runtime load than this low-power embedded panel needs. Instead: a small native isometric X/Y/Z position indicator (`CustomPainter`, no 3D engine), with an on-screen note pointing to the real 3D scene on this board's own HDMI-connected monitor. See `docs/ARCHITECTURE.md` section 4 for the full reasoning.
- **System Metrics** (`lib/ui/metrics_screen.dart`) - its own dedicated tab (not folded into the Dashboard the way iOS/Android do it) with CPU/memory/temperature/uptime tiles from `GET /api/system/metrics`, plus hostname/controller-count/robot-count/app-version from `GET /api/hydra-info`.
- **Settings** (`lib/ui/settings_screen.dart`) - connection info, server identity, sign out, and this app's own version (see [Versioning](#-versioning) below).
- **Kiosk autostart** (`kiosk/hydra-umc-dsi.service`, `kiosk/install_kiosk.sh`) - systemd unit launching the app fullscreen on `tty1` via `cage`, `Restart=always`. See "Running on the real CM5" below.
- **8-language UI** (`lib/l10n/`, standard `flutter gen-l10n` pipeline) - English, Spanish, French, German, Italian, Japanese, Chinese and Portuguese, matching every other client in this ecosystem. A persisted `Settings > Language` override defaults to the OS locale; `RobotViewModel.lastError` is a typed `HydraError` rather than pre-formatted English text, so business-logic error messages localize correctly too, not just static screen chrome.

**Status: scaffold + all 6 catalog screens implemented and connected to the real REMOTE_API.md contract.** `flutter analyze` clean, `flutter build windows` and `flutter build linux` (via WSL2) both produce a running binary, `flutter test` passes - see "Building" below for exactly what has and hasn't been verified, including the remaining gap between this WSL2 verification and the real CM5 hardware.

## 🧩 Role in HYDRA-UMC

**HYDRA-UMC-DSI** is the touch screen of the CM5 itself: a native Flutter app for the 5"/7" DSI panel that talks to `HYDRA-UMC-SERVER` over its REST and WebSocket interface, next to the browser interface of `HYDRA-UMC-STUDIO`. It holds no robot logic of its own; the server decides what is allowed.

## 🏛️ Architecture

<p align="center">
  <img src="images/architecture.svg" alt="HYDRA-UMC-DSI architecture" width="100%">
</p>

## 🚀 Quick start

Requires the stable Flutter SDK (3.x) with Linux desktop support.

```bash
flutter pub get
./run_dev.sh      # desktop simulation, no hardware (run_dev.bat on Windows)
./build_linux.sh  # on a Linux machine or the CM5: the real target
```

## 🧪 Testing

174 automated tests run with `flutter test`. They need no hardware and nothing outside this machine.

The CI runs `HYDRA_UMC_CI=1 python tools/ci_validate.py`, which checks the manifest, the documents, the eight READMEs and the pictures.

## 🏗️ Build & Release

Requires the [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel). This repo is built/verified against Flutter 3.47.0. Only `linux/` and `windows/` are configured as platforms in this repo (no `android/`, `ios/`, `web/`, or `macos/` folders) - Linux is the real target (the CM5's own OS); Windows exists purely so this app's own logic can be built, run, and tested on a machine without a Linux toolchain.

### Build scripts

```bash
./build.sh          # Git Bash / WSL, or build.bat for cmd/PowerShell - flutter pub get + flutter build windows (dev-machine verification)
./build_linux.sh    # Must run ON a real Linux machine (or the CM5 itself) - flutter pub get + flutter build linux (the real deployment target)
./run_dev.sh         # Git Bash / WSL, or run_dev.bat for cmd/PowerShell - desktop simulation mode (flutter run), no hardware needed
```

All 3 build scripts (`build.sh`/`build.bat`/`build_linux.sh`) leave the app's version alone - see [Versioning](#-versioning) below. `run_dev.sh`/`run_dev.bat` do not - a dev-loop `flutter run` is not a "real build" under that policy.

### Manual build

```bash
flutter pub get
flutter analyze                  # static analysis - no compiler needed
flutter test                     # widget tests
dart run tool/bump_version.dart  # bump the version, same as build.sh/build.bat/build_linux.sh do
flutter build windows            # dev-machine smoke test - produces build/windows/x64/runner/Release/hydra_umc_dsi.exe
flutter build linux              # the REAL target - must run on a real Linux machine, produces build/linux/*/release/bundle/
flutter run -d windows           # or -d linux on a real Linux machine, for a live desktop-simulation dev loop
```

**Honesty note on Linux verification:** `flutter build linux --release` has now actually been run against this code, from a real Ubuntu 24.04 WSL2 environment with a real Linux desktop toolchain (`cmake`, `ninja-build`, `libgtk-3-dev`, `clang`) - it builds cleanly and produces a genuine `build/linux/x64/release/bundle/hydra_umc_dsi`, confirmed to actually launch (it ran under a real X11 display and stayed alive, not just a passing exit code), not only `flutter build windows` as a smoke-test substitute. What this does **not** cover: WSL2's userspace is x86_64, not the CM5's real aarch64 Raspberry Pi OS, and `kiosk/hydra-umc-dsi.service`'s autostart flow has still never run on any real Linux box. See `docs/ARCHITECTURE.md` section 7 for the exact list of what was and wasn't verified, and "Known Follow-ups" below for what remains.

## 📂 Repository Structure

<p align="center">
  <img src="images/repository-structure.svg" alt="Repository structure of HYDRA-UMC-DSI" width="100%">
</p>

<details>
<summary>Text version of the tree</summary>

```text
HYDRA-UMC-DSI/
├── lib/                                                              source code
│   ├── main.dart                                                     App entry point, ChangeNotifierProvider + login gate, fixed dark theme
│   ├── app_version.dart                                              GENERATED - regenerated by tool/bump_version.dart, do not hand-edit
│   ├── models/                                                       data models and pure rules
│   ├── network/                                                      REST client, WebSocket and discovery
│   ├── state/                                                        the state every screen listens to
│   ├── services/                                                     services of the app (backlight)
│   ├── l10n/                                                         localizations in eight languages
│   ├── util/                                                         Helpers without a screen of their own
│   └── ui/                                                           screens and widgets
├── kiosk/                                                            kiosk unit and its installer
├── tool/                                                             version tooling
├── linux/                                                            GTK desktop runner - the REAL target, fixed 1280x720 window
├── windows/                                                          Windows desktop runner - dev-machine verification only
├── tools/                                                            project tools and CI checks
├── test/                                                             widget_test, format_uptime_test, localization_test, robot_view_model_test, robot_view_model_silent_refresh_test, auth_prefs_test, hydra_websocket_test, hostile_answers_test, hydra_error_test, play_confirmation_test, stop_long_press_test
├── .github/                                                          CI workflow and issue templates
├── images/                                                           banner and the pictures of the README
├── build.bat / build.sh                                              flutter pub get + version bump + flutter build windows (dev-machine verification)
├── build_linux.sh                                                    flutter pub get + flutter build linux (the real CM5 target - run on real Linux)
├── run_dev.bat / run_dev.sh                                          flutter run - desktop simulation mode
├── CHANGELOG.md                                                      what changed in each version
├── docs/ARCHITECTURE.md                                              architecture of the project
├── bump_manifest_version.py                                          Syncs hydra-umc.project.json's version to the native one (--sync)
├── pubspec.yaml / pubspec.lock / l10n.yaml / analysis_options.yaml   The Flutter package definition and its locked versions, the settings of the l10n generator and the lint rules
├── build-test.sh                                                     non-mutating build check
├── hydra-umc.project.json                                            manifest: version, maturity, family
└── test.sh                                                           runs the tests
```

</details>

## 🗺️ Roadmap & Known limits

**Known limits today**

Real, verified gaps this app's own code still has - not vague TODOs, each one traceable to a specific place in the code or docs above:

- **Remote-access toggle not yet independent** - `REMOTE_API.md` section 1 only recognizes `suite`, `android`, and `ios` as `X-Hydra-Client` values; this app sends `dsi`, an unrecognized value that is never gated, so its discovery requests pass through unconditionally today. Fixing this needs a 4th toggle added to HYDRA-UMC-STUDIO's own `SystemSettings.remoteAccess` type and Config > Remote Access tab - a change to that repository's server code, out of scope for this one. See `docs/ARCHITECTURE.md` section 3.
- **3D View has no real native 3D renderer** - `ui/three_d_screen.dart` currently draws a small isometric X/Y/Z position indicator instead of embedding STUDIO's real Three.js scene (`webview_flutter` has no Linux implementation - see `docs/ARCHITECTURE.md` section 4 for the full reasoning). A real native 3D renderer for this screen is future work, not started.
- **Real CM5 hardware run still pending** - `flutter build linux` itself is now verified (real Ubuntu 24.04 WSL2 toolchain, binary confirmed to actually launch - see `docs/ARCHITECTURE.md` section 7), but `build_linux.sh`'s full flow and the `kiosk/hydra-umc-dsi.service` autostart unit have still never run against the actual CM5 or any other real (non-WSL2) Linux machine. Whoever runs them there for the first time should treat that as the real first hardware deploy of this platform target, not a formality - see "Running on the real CM5" above.

## 🌍 Languages

This README and the documents of the repository exist in eight languages: English, Spanish, German, French, Italian, Japanese, Chinese and Portuguese (Portugal). They are written together and checked in the CI so that the eight files have the same sections and the same links.

## 🔗 Related Projects

This project is part of the HYDRA-UMC robotics ecosystem by the same author (JuanenRac / Electro Hobby 3D). Worth knowing about, since a request might actually be about one of these rather than this repository.

**Parent Project**
- **[HYDRA-UMC-SERVER](https://github.com/JuanenRac/HYDRA-UMC-SERVER)** — the real headless backend (REST/WebSocket) every control client actually talks to; the server this panel connects to over the real `REMOTE_API.md` contract (discovery, login, atomic commands, WebSocket sync).

**Sibling Projects** — also talk to HYDRA-UMC-SERVER's own API, each their own client
- **[HYDRA-UMC-STUDIO](https://github.com/JuanenRac/HYDRA-UMC-STUDIO)** — web control dashboard with real-time multi-robot 3D visualization.
- **[HYDRA-UMC-SUITE](https://github.com/JuanenRac/HYDRA-UMC-SUITE)** — desktop (PySide6) swarm command center for multiple servers at once, packaged as a standalone executable; speaks the exact same `REMOTE_API.md` contract as this panel.
- **[HYDRA-UMC-ANDROID-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-ANDROID-CONTROL)** — native Android control app with biometric login and a paired Wear OS companion; speaks the exact same `REMOTE_API.md` contract as this panel.
- **[HYDRA-UMC-IOS-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-IOS-CONTROL)** — iOS/iPadOS control app (Flutter) with real-time WebSocket sync; speaks the exact same `REMOTE_API.md` contract as this panel, and is where this panel's own real mDNS discovery was ported from.
- **[HYDRA-UMC-BRIDGE-AMR](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-AMR)** — coordination boundary for AGV/AMR fleets via a VDA 5050 MQTT publisher (tested against an emulated fleet only).
- **[HYDRA-UMC-BRIDGE-CNC](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-CNC)** — high-level CNC-cell coordinator with GRBL status/control-byte access (tested against an emulator only).
- **[HYDRA-UMC-BRIDGE-DROIDS](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-DROIDS)** — coordination boundary for legged/humanoid droids, with a Boston Dynamics Spot command sender (tested against an emulator only).
- **[HYDRA-UMC-BRIDGE-LASER](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-LASER)** — laser-cell coordinator reading 3 key/enclosure/interlock GPIO signals (tested against a fake chip only; it cannot arm or fire a laser).
- **[HYDRA-UMC-BRIDGE-OPENPNP](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-OPENPNP)** — safe high-level board-flow coordinator for OpenPnP pick-and-place.
- **[HYDRA-UMC-BRIDGE-PRINTER3D](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-PRINTER3D)** — safe coordination boundary for Moonraker/Klipper 3D printers, with real gated job commands.
- **[HYDRA-UMC-BRIDGE-ROS2](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-ROS2)** — coordinator with a lazily imported rclpy ROS 2 transport (not yet run against a ROS 2 installation).
- **[HYDRA-UMC-BRIDGE-UAV](https://github.com/JuanenRac/HYDRA-UMC-BRIDGE-UAV)** — coordination boundary for camera-equipped UAVs, with a MAVLink command sender (tested against an emulator only).

**Directly Related**
- **[HYDRA-UMC-WATCH](https://github.com/JuanenRac/HYDRA-UMC-WATCH)** — WearOS companion app with haptic alert patterns and a paired-phone voice relay (not yet run on a physical watch); the wearable safety alert device that complements this touch panel, carrying warnings to the operator's wrist in addition to the board's own screen.
- **[HYDRA-UMC-COGNITIVE-NODE](https://github.com/JuanenRac/HYDRA-UMC-COGNITIVE-NODE)** — integration hub for the Hailo-10 cognitive pipeline (LLM/VLA/voice orchestration); adds voice control directly on this touch panel.
- **[HYDRA-UMC-VOICE-UI](https://github.com/JuanenRac/HYDRA-UMC-VOICE-UI)** — real voice front-end (VAD + intent parser) with a bounded, confirmation-gated Watch relay; adds voice control directly on this touch panel.
- **[HYDRA-UMC-LOCAL-TECHNICIAN](https://github.com/JuanenRac/HYDRA-UMC-LOCAL-TECHNICIAN)** — local, policy-gated AI maintenance technician for the ecosystem itself - observes, diagnoses and proposes fixes; the two highest risk levels are deliberately not implemented yet.

**Also Part of the Ecosystem**

*Core Hardware & Platform*
- **[HYDRA-UMC](https://github.com/JuanenRac/HYDRA-UMC)** — the robot-arm motherboard design: CM5 host + dual-core STM32H745, meant to orchestrate up to 8 tool arms over CAN-OTA/SPI-OTA (firmware at an early stage; no populated board yet).
- **[HYDRA-UMC-OS](https://github.com/JuanenRac/HYDRA-UMC-OS)** — reproducible Raspberry Pi OS product layer for the CM5: read-only agent, validated config/profiles, WiFi first-contact provisioning.
- **[HYDRA-UMC-SDK](https://github.com/JuanenRac/HYDRA-UMC-SDK)** — the shared JSON-Schema contract and software job-gate boundary every bridge validates its commands against (not a certified safety function).
- **[HYDRA-UMC-CONNECTOR-HUB](https://github.com/JuanenRac/HYDRA-UMC-CONNECTOR-HUB)** — declarative adapter-manifest registry and validator for external-machine connectors; extends the SDK's own contract idea to external machines without replacing the industrial-gateway projects.

*Core Backend & Clients*
- **[HYDRA-UMC-EDITOR-URDF](https://github.com/JuanenRac/HYDRA-UMC-EDITOR-URDF)** — desktop graphical URDF creator/editor that pushes finished models into STUDIO's own catalog.
- **[HYDRA-UMC-EDITOR-STL](https://github.com/JuanenRac/HYDRA-UMC-EDITOR-STL)** — desktop STL model editor, transforming/replacing/removing/adding real parts in the same model catalog HYDRA-UMC-EDITOR-URDF also edits.

*URTC Tool Platform*
- **[URTC](https://github.com/JuanenRac/URTC)** — firmware for the physical Universal Robot Tool Controller PCB, 25+ tool profiles over CAN bus.
- **[URTC-FLASHER](https://github.com/JuanenRac/URTC-FLASHER)** — desktop GUI flashing tool for URTC boards, CAN-OTA plus full-chip SWD/JTAG.
- **[URTC-TESTER](https://github.com/JuanenRac/URTC-TESTER)** — desktop live CAN-bus diagnostic tool for URTC boards, one panel per tool profile.
- **[URTC-WEB-STUDIO](https://github.com/JuanenRac/URTC-WEB-STUDIO)** — browser-based alternative to URTC-TESTER via the Web Serial API, no local install needed.
- **[URTC-GATEWAY](https://github.com/JuanenRac/URTC-GATEWAY)** — gateway in front of the URTC CAN bus: an allowed list of identifiers, a rate limit and a session key; software tested on a computer, not yet on a real bus.

*Vision AI Node (Hailo-8)*
- **[HYDRA-UMC-VISION-NODE](https://github.com/JuanenRac/HYDRA-UMC-VISION-NODE)** — integration hub for the Hailo-8 vision pipeline, with a real per-stage hardware-readiness check.
- **[HYDRA-UMC-DETECTION-HEF](https://github.com/JuanenRac/HYDRA-UMC-DETECTION-HEF)** — real compiled-model registry with Hailo-architecture/checksum safe-load verification.
- **[HYDRA-UMC-VISION-STREAMER](https://github.com/JuanenRac/HYDRA-UMC-VISION-STREAMER)** — real GStreamer pipeline + MediaMTX config generator with a real HailoRT integration boundary.
- **[HYDRA-UMC-VISUAL-SERVOING-API](https://github.com/JuanenRac/HYDRA-UMC-VISUAL-SERVOING-API)** — Position-Based Visual Servoing correction law with authorisation gated on the zone state; no camera pose estimation yet.
- **[HYDRA-UMC-SAFETY-ZONES](https://github.com/JuanenRac/HYDRA-UMC-SAFETY-ZONES)** — v0 zone-breach, calibration-freshness and E-STOP-request logic that takes object positions from a file; no detector feeds it and no physical E-STOP is wired to it yet.

*Cognitive AI Node (Hailo-10)*
- **[HYDRA-UMC-VLA-ENGINE](https://github.com/JuanenRac/HYDRA-UMC-VLA-ENGINE)** — real action-token encoding/decoding and trajectory generation for a Vision-Language-Action model.
- **[HYDRA-UMC-SEMANTIC-PLANNER](https://github.com/JuanenRac/HYDRA-UMC-SEMANTIC-PLANNER)** — real rule-based task decomposition and semantic error recovery over MCU error codes.
- **[HYDRA-UMC-DOCS-QA](https://github.com/JuanenRac/HYDRA-UMC-DOCS-QA)** — real stdlib-only TF-IDF document search over this ecosystem's own Markdown docs.

*Orchestration & Swarm*
- **[HYDRA-UMC-ORCHESTRATOR](https://github.com/JuanenRac/HYDRA-UMC-ORCHESTRATOR)** — integration hub with a real gRPC/Protobuf health-report contract and mission state machine.
- **[HYDRA-UMC-JOB-DISPATCHER](https://github.com/JuanenRac/HYDRA-UMC-JOB-DISPATCHER)** — real priority-based job queue with deduplication, over a real HTTP API.
- **[HYDRA-UMC-NODE-HEALING](https://github.com/JuanenRac/HYDRA-UMC-NODE-HEALING)** — real gRPC-based fleet health watchdog with retry/backoff and identity-mismatch detection.
- **[HYDRA-UMC-PATH-PLANNER-3D](https://github.com/JuanenRac/HYDRA-UMC-PATH-PLANNER-3D)** — real RRT-based 3D path planner with real obstacle/workspace collision validation.
- **[HYDRA-UMC-SWARM-SYNC](https://github.com/JuanenRac/HYDRA-UMC-SWARM-SYNC)** — real CRDT LWW-Element-Map state sync, property-tested for multi-cell convergence.

*Digital Twin & Simulation*
- **[HYDRA-UMC-TWIN](https://github.com/JuanenRac/HYDRA-UMC-TWIN)** — integration hub for the digital-twin engine, with a real version-compatibility sync contract.
- **[HYDRA-UMC-HIL-BRIDGE](https://github.com/JuanenRac/HYDRA-UMC-HIL-BRIDGE)** — hardware-in-the-loop router with a software collision interlock between simulation and real hardware (tested without real hardware).
- **[HYDRA-UMC-PHYSICS-REPLICA](https://github.com/JuanenRac/HYDRA-UMC-PHYSICS-REPLICA)** — real forward kinematics and joint-limit validation over a real URDF subset.
- **[HYDRA-UMC-SYNTHETIC-DATA-GEN](https://github.com/JuanenRac/HYDRA-UMC-SYNTHETIC-DATA-GEN)** — real procedural 2D scene generator with YOLO/COCO annotation export.

*Data & Analytics*
- **[HYDRA-UMC-DATALAKE](https://github.com/JuanenRac/HYDRA-UMC-DATALAKE)** — real sqlite3-backed time-series store with a real ingest/query HTTP API.
- **[HYDRA-UMC-ANOMALY-DETECTOR](https://github.com/JuanenRac/HYDRA-UMC-ANOMALY-DETECTOR)** — real FFT + statistical baseline anomaly detector with drift monitoring.
- **[HYDRA-UMC-PRODUCTION-REPORTS](https://github.com/JuanenRac/HYDRA-UMC-PRODUCTION-REPORTS)** — real OEE/availability calculation over DATALAKE history, with reproducible CSV export.
- **[HYDRA-UMC-TELEMETRY-COLLECTOR](https://github.com/JuanenRac/HYDRA-UMC-TELEMETRY-COLLECTOR)** — real CAN/WebSocket ingestion pipeline into DATALAKE, with sequence deduplication.

*Industrial Gateway*
- **[HYDRA-UMC-GATEWAY-INDUSTRIAL](https://github.com/JuanenRac/HYDRA-UMC-GATEWAY-INDUSTRIAL)** — integration hub relaying to industrial protocols, with a real command allowlist/backpressure layer.
- **[HYDRA-UMC-OPCUA-SERVER](https://github.com/JuanenRac/HYDRA-UMC-OPCUA-SERVER)** — real OPC-UA address space, verified with a real binary-protocol client session.
- **[HYDRA-UMC-MQTT-BROKER](https://github.com/JuanenRac/HYDRA-UMC-MQTT-BROKER)** — real MQTT broker with optional per-client authentication and topic ACLs.
- **[HYDRA-UMC-MTCONNECT-ADAPTER](https://github.com/JuanenRac/HYDRA-UMC-MTCONNECT-ADAPTER)** — real MTConnect `/probe` and `/current` XML endpoints with degraded-mode output.

*Complementary Tools & Ecosystem Operations*
- **[HYDRA-UMC-DASHBOARD-AI](https://github.com/JuanenRac/HYDRA-UMC-DASHBOARD-AI)** — Smart Summaries and Anomaly Highlighting panels over DATALAKE/ANOMALY-DETECTOR, with an honest statistical fallback.
- **[HYDRA-UMC-TOOL-CLI](https://github.com/JuanenRac/HYDRA-UMC-TOOL-CLI)** — fleet CLI with a real, stable exit-code contract, a genuine live client of HYDRA-UMC-SERVER's own API.
- **[URTC-SMART-RACK](https://github.com/JuanenRac/URTC-SMART-RACK)** — firmware for a board-mounting rack with real tool-ID decoding and Smart Idle pre-heating logic.
- **[URTC-VISION-TOOL](https://github.com/JuanenRac/URTC-VISION-TOOL)** — firmware plus a real Python vision companion for a thermal/RGB inspection tool head.
- **[HYDRA-UMC-UPDATER](https://github.com/JuanenRac/HYDRA-UMC-UPDATER)** — administrative desktop tool that discovers, clones and updates every repo in this ecosystem.
- **[HYDRA-UMC-OS-REBUILDER](https://github.com/JuanenRac/HYDRA-UMC-OS-REBUILDER)** — Windows/Linux desktop tool that builds a ready-to-flash CM5 image pre-loaded with the ecosystem's most current versions, with Raspberry-Pi-Imager-style first-boot Wi-Fi/user/SSH configuration.
- **[HYDRA-UMC-OPS-AGENT](https://github.com/JuanenRac/HYDRA-UMC-OPS-AGENT)** — maintenance-incident coordinator: a low-privilege edge role collects a sanitized inventory/health snapshot, a control-plane role renders it read-only and asks an AI provider to suggest a diagnosis - never applies a patch or deploys anything.
- **[HYDRA-UMC-DEV-SERVER](https://github.com/JuanenRac/HYDRA-UMC-DEV-SERVER)** — reproducible development host (Raspberry Pi 5 / CM5) that stores the ecosystem's source and runs bounded build/test tasks under a durable queue; a dedicated dev role, explicitly not an operational CM5.

## 📚 Documentation

Where to read more:

* [Security baseline of the ecosystem](https://github.com/JuanenRac/HYDRA-UMC-DOCS/blob/main/docs/SECURITY_BASELINE.md)
* [Threat model of the ecosystem](https://github.com/JuanenRac/HYDRA-UMC-DOCS/blob/main/docs/THREAT_MODEL.md)
* [Changelog of this repository](CHANGELOG.md)
* [License of this repository](LICENSE.md)

## 🤝 Contributing & Community

* Before a pull request run `HYDRA_UMC_CI=1 py -3 tools/ci_validate.py` (or `HYDRA_UMC_CI=1 python3 tools/ci_validate.py`): it must print `CI_VALIDATION=PASS`. Do not run `build.sh` or `build.bat` for this check; building is not a check.
* The eight READMEs are written from one source in HYDRA-UMC-DOCS; do not edit them by hand. Change the source and write them again with `tools/make_readmes.py`.
* Do not state in a README what has not run: say "simulated" or "not tried on hardware" where that is the truth.
* See [CONTRIBUTING.md](CONTRIBUTING.md), the [code of conduct](CODE_OF_CONDUCT.md), [SECURITY.md](SECURITY.md) and [SUPPORT.md](SUPPORT.md).

## 👤 AUTHOR

**JuanenRac (Electro Hobby 3D)** · electrohobby3d@gmail.com

## 📜 LICENSE

GPL-3.0-or-later - [LICENSE](LICENSE).
