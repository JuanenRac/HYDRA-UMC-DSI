<p align="center">
  <img src="images/HYDRA_UMC_BANNER.svg" alt="HYDRA-UMC-DSI banner" width="100%">
</p>
# 🖥️ HYDRA-UMC DSI

<p align="center">
  🇺🇸 <b>English</b> |
  <a href="README_spa.md">🇪🇸 Español</a> |
  <a href="README_fra.md">🇫🇷 Français</a> |
  <a href="README_ita.md">🇮🇹 Italiano</a> |
  <a href="README_deu.md">🇩🇪 Deutsch</a> |
  <a href="README_zho.md">🇨🇳 简体中文</a> |
  <a href="README_jpn.md">🇯🇵 日本語</a>
</p>


<p align="left">
  <img src="https://img.shields.io/badge/License-GPL%203.0-blue.svg" alt="GPL 3.0">
  <img src="https://img.shields.io/badge/Framework-Flutter%203.x-02569B.svg" alt="Flutter">
  <img src="https://img.shields.io/badge/Language-Dart-0175C2.svg" alt="Dart">
  <img src="https://img.shields.io/badge/Platform-Linux%20%7C%20CM5-E34F26.svg" alt="Platform">
</p>


A native Flutter touch UI (Dart, real Linux desktop target) for HYDRA-UMC's own 5"/7" DSI touchscreen on the Compute Module 5 - both physical panel sizes share the exact same 1280x720 pixel resolution, so this app ships one fixed, non-responsive layout instead of adapting to two sizes. It speaks the exact same [`REMOTE_API.md`](https://github.com/JuanenRac/HYDRA-UMC-STUDIO/blob/main/docs/REMOTE_API.md) contract [HYDRA-UMC SUITE](https://github.com/JuanenRac/HYDRA-UMC-SUITE), [HYDRA-UMC-ANDROID-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-ANDROID-CONTROL), and [HYDRA-UMC-IOS-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-IOS-CONTROL) use - discovery, login, atomic per-robot commands, and live WebSocket sync against a running [HYDRA-UMC STUDIO](https://github.com/JuanenRac/HYDRA-UMC-STUDIO) server, run directly on the board itself rather than over a browser tab. See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for the full design, including why Flutter (not Kivy) and why the 3D screen isn't a WebView.

**This app is one of two coexisting control surfaces on the same board** - the CM5 also drives an HDMI output for a full external monitor running the browser UI. This DSI app complements that path with a direct, always-on touch console at the board itself; it does not replace the browser UI.

## 🏗️ What's implemented

- **Login** (`lib/ui/login_screen.dart`, `lib/state/robot_view_model.dart`) - server IP/port + username/password fields sized for touch, `POST /api/login` against `admin`/`admin` (pre-filled - the default account every server in this ecosystem seeds on its own first-ever start; additional lower-privilege "operator" accounts can be created from Config > Users in the browser UI), session token persisted across launches via `shared_preferences` - important on a kiosk panel expected to stay signed in across a CM5 power-cycle, not just an app relaunch. A "Scan local network" dialog (`lib/network/discovery.dart`) finds servers without needing to already know the IP - doubly useful here, since the CM5 this app runs on is often the very controller it should connect to.
- **Network discovery** (`lib/network/discovery.dart`) - two paths run in parallel from the same "Scan local network" dialog: real mDNS/Bonjour (`discoverMdns()`, querying `server.ts`'s own `_hydra._tcp` publish via the `multicast_dns` package) and a concurrent brute-force scan of `GET /api/hydra-info` across this device's own real local subnet(s) (`scanSubnets()`), deduplicated by host:port - ported from HYDRA-UMC-IOS-CONTROL, the first client in this ecosystem to add real mDNS discovery.
- **Atomic command sync** (`lib/state/robot_view_model.dart`'s own `_sendAtomicCommand()`) - every write (enable/disable/play/pause/stop/jog/valve/pump/speed/vision) uses the real `POST /api/robot/:id/command` endpoint, with correct combined-robot (`combinedWith`) propagation and a rollback to the pre-mutation snapshot if the request fails - especially important for a jog pendant/E-STOP a few feet from the actual robots.
- **Live WebSocket sync** (`lib/network/hydra_websocket.dart`) - always attaches `?token=`, handles both `"settings"` and `"delta"` broadcast types, auto-reconnects on drop.
- **Horizontal touch navigation** (`lib/ui/main_screen.dart`) - a persistent top bar of 6 large icon+label tabs (Dashboard/Control/Camera/3D View/Metrics/Settings) across the fixed 1280px width, KlipperScreen-in-spirit rather than a phone-style bottom nav bar - matching the catalog the project owner asked for, reorganized for a wide touch panel instead of a vertical phone layout.
- **Dashboard** (`lib/ui/dashboard_screen.dart`) - per-robot cards, reactive in real time via `Provider`, LED convention (green pulsing = active, red solid = inactive), combined-robot display, and module chips (CAM/XY/ATC/PNP/CNC/LSR/BED/VAC/RCK) - same visual language as every other client in this ecosystem.
- **Manual Control** (`lib/ui/control_screen.dart`, `lib/ui/widgets/joystick_pad.dart`) - side-by-side layout (jog pad left, telemetry/speed/IO right) sized for the 1280x720 frame instead of a single scrolling column, real long-press protection on E-STOP/STOP (a quick tap does nothing but a haptic + visual hint, only a genuine hold sends the command), speed/acceleration sliders, valve/pump toggles.
- **Camera** (`lib/ui/camera_screen.dart`, `lib/ui/widgets/mjpeg_view.dart`) - the same hand-rolled, dependency-free MJPEG stream parser as HYDRA-UMC-IOS-CONTROL (no WebView, no platform-specific code - it just works on Linux desktop unmodified), a clear "Camera Disabled" state, and a switch to turn a robot's vision system on/off directly from the server.
- **3D View** (`lib/ui/three_d_screen.dart`) - **not** a WebView embed of STUDIO's real Three.js scene, unlike the iOS/Android apps - `webview_flutter` has no Linux desktop implementation at all, and a full browser engine is a heavier runtime load than this low-power embedded panel needs. Instead: a small native isometric X/Y/Z position indicator (`CustomPainter`, no 3D engine), with an on-screen note pointing to the real 3D scene on this board's own HDMI-connected monitor. See `docs/ARCHITECTURE.md` section 4 for the full reasoning.
- **System Metrics** (`lib/ui/metrics_screen.dart`) - its own dedicated tab (not folded into the Dashboard the way iOS/Android do it) with CPU/memory/temperature/uptime tiles from `GET /api/system/metrics`, plus hostname/controller-count/robot-count/app-version from `GET /api/hydra-info`.
- **Settings** (`lib/ui/settings_screen.dart`) - connection info, server identity, sign out, and this app's own version (see [Versioning](#-versioning) below).
- **Kiosk autostart** (`kiosk/hydra-umc-dsi.service`, `kiosk/install_kiosk.sh`) - systemd unit launching the app fullscreen on `tty1` via `cage`, `Restart=always`. See "Running on the real CM5" below.

**Status: scaffold + all 6 catalog screens implemented and connected to the real REMOTE_API.md contract.** `flutter analyze` clean, `flutter build windows` produces a running binary, `flutter test` passes - see "Building" below for exactly what could and couldn't be verified from this Windows working environment, since the real target is Linux.

## 🚀 Building

Requires the [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel). This repo is built/verified against Flutter 3.47.0. Only `linux/` and `windows/` are configured as platforms in this repo (no `android/`, `ios/`, `web/`, or `macos/` folders) - Linux is the real target (the CM5's own OS); Windows exists purely so this app's own logic can be built, run, and tested on a machine without a Linux toolchain.

### Build scripts

```bash
./build.sh          # Git Bash / WSL, or build.bat for cmd/PowerShell - flutter pub get + version bump + flutter build windows (dev-machine verification)
./build_linux.sh    # Must run ON a real Linux machine (or the CM5 itself) - flutter pub get + version bump + flutter build linux (the real deployment target)
./run_dev.sh         # Git Bash / WSL, or run_dev.bat for cmd/PowerShell - desktop simulation mode (flutter run), no hardware needed
```

All 3 build scripts (`build.sh`/`build.bat`/`build_linux.sh`) bump the app's version first - see [Versioning](#-versioning) below. `run_dev.sh`/`run_dev.bat` do not - a dev-loop `flutter run` is not a "real build" under that policy.

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

**Honesty note on Linux verification:** this repo was authored on a Windows machine with no Linux build toolchain available (confirmed via `wsl --status` - no WSL distro installed). `flutter build linux` has never actually been run against this code from this working environment; `flutter build windows` was used as the smoke-test substitute the task explicitly allows for. See `docs/ARCHITECTURE.md` section 7 for the exact list of what was and wasn't verified, and `mejoras_futuras.txt` for the follow-up.

## 🔢 Versioning

This repo follows an ecosystem-wide policy (shared with
[HYDRA-UMC-IOS-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-IOS-CONTROL),
implemented there in parallel): the version bumps automatically on
**every real build**, no manual editing of `pubspec.yaml`'s `version:`
line. `build.sh`/`build.bat`/`build_linux.sh` run `tool/bump_version.dart`
before invoking `flutter build`, applying:

- **Patch, odometer-style (base 10):** +1 on every build; once it would
  exceed 9 it resets to 0 and minor gets +1 instead - e.g. `0.0.9` ->
  `0.1.0`. Major is never touched automatically.
- **Build number** (the part after `+`): a plain monotonic counter, +1 on
  every build, no carry.

The same script regenerates `lib/app_version.dart` (generated, not
hand-edited - a plain `const` file, not a new runtime dependency like
`package_info_plus`), which the app reads at runtime to show its own
version on the **Settings** screen. See [CHANGELOG.md](CHANGELOG.md) for
the version history.

### Running on the real CM5

After `build_linux.sh` produces `build/linux/*/release/bundle/`, copy the whole `bundle/` directory to the CM5 (it depends on the `.so` files alongside the binary, not just the executable itself) to `/opt/hydra-umc-dsi/bundle/`, then run `sudo kiosk/install_kiosk.sh` to install and enable `kiosk/hydra-umc-dsi.service`, a systemd unit that launches the app fullscreen on `tty1` via [`cage`](https://github.com/cage-kiosk/cage) (a minimal Wayland kiosk compositor that runs exactly one fullscreen client), with `Restart=always` so a crash re-launches it rather than dropping to a blank screen. Chosen over [`flutter-pi`](https://github.com/ardera/flutter-pi) (a third-party bare-metal Flutter engine embedder for Raspberry Pi, running without any window system at all) specifically because it reuses `build_linux.sh`'s own real `flutter build linux` output unmodified - flutter-pi builds against the Flutter engine directly instead, so it would need its own separate build step, not a drop-in on top of the build this repo already produces. **Honesty note:** written and reviewed, never actually run against a real CM5 or any other Linux box - same unverified status as `flutter build linux` itself (see `docs/ARCHITECTURE.md` section 7). See `kiosk/hydra-umc-dsi.service`'s own header comment for the exact assumptions (root service user, `tty1` ownership) that would need checking against whatever Raspberry Pi OS image the CM5 actually runs. **The real, deployed HDMI kiosk on the real CM5 today is HYDRA-UMC-OS's own `provisioning/install_kiosk.sh`** (minimal X11 + Chromium, verified on real hardware) - installing this app's own `cage`-based kiosk on the same device would fight it for `tty1`. Nobody has decided this native app replaces the Chromium kiosk; verify this one actually runs first, and stop the other kiosk before ever enabling both.

## 📂 Repository Structure

```text
HYDRA-UMC-DSI/
├── build.bat, build.sh              # flutter pub get + version bump + flutter build windows (dev-machine verification)
├── build_linux.sh                   # flutter pub get + version bump + flutter build linux (the real CM5 target - run on real Linux)
├── run_dev.bat, run_dev.sh          # flutter run - desktop simulation mode
├── CHANGELOG.md                      # version history (see Versioning above)
├── kiosk/
│   ├── hydra-umc-dsi.service        # systemd unit - fullscreen autostart via cage
│   └── install_kiosk.sh             # installs + enables the unit above (run on the real CM5)
├── tool/
│   └── bump_version.dart            # Version-bump script build.bat/build.sh/build_linux.sh run before every build (see Versioning above)
├── lib/
│   ├── main.dart                    # App entry point, ChangeNotifierProvider + login gate, fixed dark theme
│   ├── app_version.dart             # GENERATED - regenerated by tool/bump_version.dart, do not hand-edit
│   ├── models/
│   │   ├── server_info.dart         # Discovery/connection entry - mirrors ServerInfo in the other 3 clients
│   │   └── hydra_state.dart         # RobotView/ControllerView/HydraState - thin mutable views over the raw settings.json tree
│   ├── network/
│   │   ├── hydra_api_client.dart    # REST: login, settings, atomic robot command, system metrics - X-Hydra-Client: dsi
│   │   ├── hydra_websocket.dart     # /ws live sync client
│   │   ├── discovery.dart           # Concurrent scan of this device's own real local subnet(s)
│   │   └── auth_prefs.dart          # Persisted connection + token (shared_preferences)
│   ├── state/
│   │   └── robot_view_model.dart    # Single ChangeNotifier every screen listens to
│   └── ui/
│       ├── login_screen.dart        # Host/port/user/pass fields + "Scan local network"
│       ├── main_screen.dart         # Horizontal touch nav bar (6 tabs) - KlipperScreen-in-spirit
│       ├── dashboard_screen.dart    # Per-robot cards + system metrics bar
│       ├── control_screen.dart      # Jog/speed/valve/pump/playback controls, side-by-side touch layout
│       ├── camera_screen.dart       # MJPEG viewer + vision on/off switch
│       ├── three_d_screen.dart      # Native isometric X/Y/Z indicator - NOT a WebView (see docs/ARCHITECTURE.md §4)
│       ├── metrics_screen.dart      # Dedicated CM5 host metrics + server identity tab
│       ├── settings_screen.dart     # Connection info + sign out + own app version
│       └── widgets/
│           ├── joystick_pad.dart     # Jog D-pad, sized up for touch
│           ├── digital_readout.dart, status_led.dart
│           └── mjpeg_view.dart       # Hand-rolled MJPEG stream parser
├── linux/                            # GTK desktop runner - the REAL target, fixed 1280x720 window
├── windows/                          # Windows desktop runner - dev-machine verification only
├── docs/ARCHITECTURE.md
├── test/widget_test.dart
├── README.md                         # this file
└── README_spa.md / README_ita.md / README_fra.md / README_deu.md / README_zho.md / README_jpn.md  # translations
```

## 🔗 Related Projects

This project is part of a much larger robotics ecosystem by the same author (JuanenRac / Electro Hobby 3D), spanning core platform control, vision and cognitive AI nodes, swarm orchestration, digital twins, data analytics, and industrial integration across many projects. Worth knowing about, since a request might actually be about one of these rather than this repository.

**Directly related to HYDRA-UMC-DSI**
- **[HYDRA-UMC-STUDIO](https://github.com/JuanenRac/HYDRA-UMC-STUDIO)** — the server this panel connects to over the real `REMOTE_API.md` contract (discovery, login, atomic commands, WebSocket sync).
- **[HYDRA-UMC-SUITE](https://github.com/JuanenRac/HYDRA-UMC-SUITE)**, **[HYDRA-UMC-ANDROID-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-ANDROID-CONTROL)**, **[HYDRA-UMC-IOS-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-IOS-CONTROL)** — sibling clients that speak the exact same `REMOTE_API.md` contract as this panel; the iOS app in particular is where this panel's real mDNS discovery was ported from.
- **[HYDRA-UMC-WATCH](https://github.com/JuanenRac/HYDRA-UMC-WATCH)** — wearable safety alert device that complements this touch panel, carrying warnings to the operator's wrist in addition to the board's own screen.
- **[HYDRA-UMC-COGNITIVE-NODE](https://github.com/JuanenRac/HYDRA-UMC-COGNITIVE-NODE)** — adds voice control directly on this touch panel.
- **[HYDRA-UMC-VOICE-UI](https://github.com/JuanenRac/HYDRA-UMC-VOICE-UI)** — adds voice control directly on this touch panel.

**Rest of the ecosystem**

💠 **Core Ecosystem**: [HYDRA-UMC](https://github.com/JuanenRac/HYDRA-UMC) · [HYDRA-UMC-SERVER](https://github.com/JuanenRac/HYDRA-UMC-SERVER) · [HYDRA-UMC-STUDIO](https://github.com/JuanenRac/HYDRA-UMC-STUDIO) · [HYDRA-UMC-SUITE](https://github.com/JuanenRac/HYDRA-UMC-SUITE) · [HYDRA-UMC-ANDROID-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-ANDROID-CONTROL) · [HYDRA-UMC-IOS-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-IOS-CONTROL) · [HYDRA-UMC-EDITOR-URDF](https://github.com/JuanenRac/HYDRA-UMC-EDITOR-URDF) · [URTC](https://github.com/JuanenRac/URTC) · [URTC-FLASHER](https://github.com/JuanenRac/URTC-FLASHER) · [URTC-TESTER](https://github.com/JuanenRac/URTC-TESTER) · [URTC-WEB-STUDIO](https://github.com/JuanenRac/URTC-WEB-STUDIO)

👁️ **Vision AI Node (Hailo-8)**: [HYDRA-UMC-VISION-NODE](https://github.com/JuanenRac/HYDRA-UMC-VISION-NODE) · [HYDRA-UMC-VISION-STREAMER](https://github.com/JuanenRac/HYDRA-UMC-VISION-STREAMER) · [HYDRA-UMC-DETECTION-HEF](https://github.com/JuanenRac/HYDRA-UMC-DETECTION-HEF) · [HYDRA-UMC-SAFETY-ZONES](https://github.com/JuanenRac/HYDRA-UMC-SAFETY-ZONES) · [HYDRA-UMC-VISUAL-SERVOING-API](https://github.com/JuanenRac/HYDRA-UMC-VISUAL-SERVOING-API)

🧠 **Cognitive AI Node (Hailo-10)**: [HYDRA-UMC-VLA-ENGINE](https://github.com/JuanenRac/HYDRA-UMC-VLA-ENGINE) · [HYDRA-UMC-SEMANTIC-PLANNER](https://github.com/JuanenRac/HYDRA-UMC-SEMANTIC-PLANNER) · [HYDRA-UMC-DOCS-QA](https://github.com/JuanenRac/HYDRA-UMC-DOCS-QA)

🐝 **Orchestration & Swarm**: [HYDRA-UMC-ORCHESTRATOR](https://github.com/JuanenRac/HYDRA-UMC-ORCHESTRATOR) · [HYDRA-UMC-SWARM-SYNC](https://github.com/JuanenRac/HYDRA-UMC-SWARM-SYNC) · [HYDRA-UMC-PATH-PLANNER-3D](https://github.com/JuanenRac/HYDRA-UMC-PATH-PLANNER-3D) · [HYDRA-UMC-JOB-DISPATCHER](https://github.com/JuanenRac/HYDRA-UMC-JOB-DISPATCHER) · [HYDRA-UMC-NODE-HEALING](https://github.com/JuanenRac/HYDRA-UMC-NODE-HEALING)

🎮 **Digital Twin & Simulation**: [HYDRA-UMC-TWIN](https://github.com/JuanenRac/HYDRA-UMC-TWIN) · [HYDRA-UMC-PHYSICS-REPLICA](https://github.com/JuanenRac/HYDRA-UMC-PHYSICS-REPLICA) · [HYDRA-UMC-HIL-BRIDGE](https://github.com/JuanenRac/HYDRA-UMC-HIL-BRIDGE) · [HYDRA-UMC-SYNTHETIC-DATA-GEN](https://github.com/JuanenRac/HYDRA-UMC-SYNTHETIC-DATA-GEN)

📊 **Data & Analytics**: [HYDRA-UMC-DATALAKE](https://github.com/JuanenRac/HYDRA-UMC-DATALAKE) · [HYDRA-UMC-TELEMETRY-COLLECTOR](https://github.com/JuanenRac/HYDRA-UMC-TELEMETRY-COLLECTOR) · [HYDRA-UMC-ANOMALY-DETECTOR](https://github.com/JuanenRac/HYDRA-UMC-ANOMALY-DETECTOR) · [HYDRA-UMC-PRODUCTION-REPORTS](https://github.com/JuanenRac/HYDRA-UMC-PRODUCTION-REPORTS)

🏭 **Industrial Gateway**: [HYDRA-UMC-GATEWAY-INDUSTRIAL](https://github.com/JuanenRac/HYDRA-UMC-GATEWAY-INDUSTRIAL) · [HYDRA-UMC-OPCUA-SERVER](https://github.com/JuanenRac/HYDRA-UMC-OPCUA-SERVER) · [HYDRA-UMC-MQTT-BROKER](https://github.com/JuanenRac/HYDRA-UMC-MQTT-BROKER) · [HYDRA-UMC-MTCONNECT-ADAPTER](https://github.com/JuanenRac/HYDRA-UMC-MTCONNECT-ADAPTER)

🛠️ **Complementary Tools**: [URTC-SMART-RACK](https://github.com/JuanenRac/URTC-SMART-RACK) · [URTC-VISION-TOOL](https://github.com/JuanenRac/URTC-VISION-TOOL) · [HYDRA-UMC-TOOL-CLI](https://github.com/JuanenRac/HYDRA-UMC-TOOL-CLI) · [HYDRA-UMC-DASHBOARD-AI](https://github.com/JuanenRac/HYDRA-UMC-DASHBOARD-AI)

---

## 👤 Author

**JuanenRac** (Electro Hobby 3D)
📧 electrohobby3d@gmail.com
📺 youtube.com/@electrohobby3d

---

## 📜 License

GNU General Public License v3.0 (GPL-3.0) for the source code - see [`LICENSE`](LICENSE).

The documentation (this README and its own translations - `README_spa.md`, `README_ita.md`, `README_fra.md`, `README_deu.md`, `README_zho.md`, `README_jpn.md`) is available under **Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)**. Full text at https://creativecommons.org/licenses/by-sa/4.0/.
