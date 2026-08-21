# 🖥️ HYDRA-UMC DSI

A native Flutter touch UI (Dart, real Linux desktop target) for HYDRA-UMC's own 5"/7" DSI touchscreen on the Compute Module 5 - both physical panel sizes share the exact same 1280x720 pixel resolution, so this app ships one fixed, non-responsive layout instead of adapting to two sizes. It speaks the exact same [`REMOTE_API.md`](https://github.com/JuanenRac/HYDRA-UMC-STUDIO/blob/main/docs/REMOTE_API.md) contract [HYDRA-UMC SUITE](https://github.com/JuanenRac/HYDRA-UMC-SUITE), [HYDRA-UMC-ANDROID-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-ANDROID-CONTROL), and [HYDRA-UMC-IOS-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-IOS-CONTROL) use - discovery, login, atomic per-robot commands, and live WebSocket sync against a running [HYDRA-UMC STUDIO](https://github.com/JuanenRac/HYDRA-UMC-STUDIO) server, run directly on the board itself rather than over a browser tab. See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for the full design, including why Flutter (not Kivy) and why the 3D screen isn't a WebView.

**This app is one of two coexisting control surfaces on the same board** - the CM5 also drives an HDMI output for a full external monitor running the browser UI. This DSI app complements that path with a direct, always-on touch console at the board itself; it does not replace the browser UI.

## 🏗️ What's implemented

- **Login** (`lib/ui/login_screen.dart`, `lib/state/robot_view_model.dart`) - server IP/port + username/password fields sized for touch, `POST /api/login` against `admin`/`admin` (pre-filled - the default account every server in this ecosystem seeds on its own first-ever start; additional lower-privilege "operator" accounts can be created from Config > Users in the browser UI), session token persisted across launches via `shared_preferences` - important on a kiosk panel expected to stay signed in across a CM5 power-cycle, not just an app relaunch. A "Scan local network" dialog (`lib/network/discovery.dart`) finds servers without needing to already know the IP - doubly useful here, since the CM5 this app runs on is often the very controller it should connect to.
- **Network discovery** (`lib/network/discovery.dart`) - concurrent scan of `GET /api/hydra-info` across this device's own real local subnet(s), ported unmodified from HYDRA-UMC-IOS-CONTROL.
- **Atomic command sync** (`lib/state/robot_view_model.dart`'s own `_sendAtomicCommand()`) - every write (enable/disable/play/pause/stop/jog/valve/pump/speed/vision) uses the real `POST /api/robot/:id/command` endpoint, with correct combined-robot (`combinedWith`) propagation and a rollback to the pre-mutation snapshot if the request fails - especially important for a jog pendant/E-STOP a few feet from the actual robots.
- **Live WebSocket sync** (`lib/network/hydra_websocket.dart`) - always attaches `?token=`, handles both `"settings"` and `"delta"` broadcast types, auto-reconnects on drop.
- **Horizontal touch navigation** (`lib/ui/main_screen.dart`) - a persistent top bar of 6 large icon+label tabs (Dashboard/Control/Camera/3D View/Metrics/Settings) across the fixed 1280px width, KlipperScreen-in-spirit rather than a phone-style bottom nav bar - matching the catalog the project owner asked for, reorganized for a wide touch panel instead of a vertical phone layout.
- **Dashboard** (`lib/ui/dashboard_screen.dart`) - per-robot cards, reactive in real time via `Provider`, LED convention (green pulsing = active, red solid = inactive), combined-robot display, and module chips (CAM/XY/ATC/PNP/CNC/LSR/BED/VAC/RCK) - same visual language as every other client in this ecosystem.
- **Manual Control** (`lib/ui/control_screen.dart`, `lib/ui/widgets/joystick_pad.dart`) - side-by-side layout (jog pad left, telemetry/speed/IO right) sized for the 1280x720 frame instead of a single scrolling column, real long-press protection on E-STOP/STOP (a quick tap does nothing but a haptic + visual hint, only a genuine hold sends the command), speed/acceleration sliders, valve/pump toggles.
- **Camera** (`lib/ui/camera_screen.dart`, `lib/ui/widgets/mjpeg_view.dart`) - the same hand-rolled, dependency-free MJPEG stream parser as HYDRA-UMC-IOS-CONTROL (no WebView, no platform-specific code - it just works on Linux desktop unmodified), a clear "Camera Disabled" state, and a switch to turn a robot's vision system on/off directly from the server.
- **3D View** (`lib/ui/three_d_screen.dart`) - **not** a WebView embed of STUDIO's real Three.js scene, unlike the iOS/Android apps - `webview_flutter` has no Linux desktop implementation at all, and a full browser engine is a heavier runtime load than this low-power embedded panel needs. Instead: a small native isometric X/Y/Z position indicator (`CustomPainter`, no 3D engine), with an on-screen note pointing to the real 3D scene on this board's own HDMI-connected monitor. See `docs/ARCHITECTURE.md` section 4 for the full reasoning.
- **System Metrics** (`lib/ui/metrics_screen.dart`) - its own dedicated tab (not folded into the Dashboard the way iOS/Android do it) with CPU/memory/temperature/uptime tiles from `GET /api/system/metrics`, plus hostname/controller-count/robot-count/app-version from `GET /api/hydra-info`.
- **Settings** (`lib/ui/settings_screen.dart`) - connection info, server identity, and sign out.

**Status: scaffold + all 6 catalog screens implemented and connected to the real REMOTE_API.md contract.** `flutter analyze` clean, `flutter build windows` produces a running binary, `flutter test` passes - see "Building" below for exactly what could and couldn't be verified from this Windows working environment, since the real target is Linux.

## 🚀 Building

Requires the [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel). This repo is built/verified against Flutter 3.47.0. Only `linux/` and `windows/` are configured as platforms in this repo (no `android/`, `ios/`, `web/`, or `macos/` folders) - Linux is the real target (the CM5's own OS); Windows exists purely so this app's own logic can be built, run, and tested on a machine without a Linux toolchain.

### Build scripts

```bash
./build.sh          # Git Bash / WSL, or build.bat for cmd/PowerShell - flutter pub get + flutter build windows (dev-machine verification)
./build_linux.sh    # Must run ON a real Linux machine (or the CM5 itself) - flutter build linux (the real deployment target)
./run_dev.sh         # Git Bash / WSL, or run_dev.bat for cmd/PowerShell - desktop simulation mode (flutter run), no hardware needed
```

### Manual build

```bash
flutter pub get
flutter analyze          # static analysis - no compiler needed
flutter test             # widget tests
flutter build windows    # dev-machine smoke test - produces build/windows/x64/runner/Release/hydra_umc_dsi.exe
flutter build linux      # the REAL target - must run on a real Linux machine, produces build/linux/*/release/bundle/
flutter run -d windows   # or -d linux on a real Linux machine, for a live desktop-simulation dev loop
```

**Honesty note on Linux verification:** this repo was authored on a Windows machine with no Linux build toolchain available (confirmed via `wsl --status` - no WSL distro installed). `flutter build linux` has never actually been run against this code from this working environment; `flutter build windows` was used as the smoke-test substitute the task explicitly allows for. See `docs/ARCHITECTURE.md` section 7 for the exact list of what was and wasn't verified, and `mejoras_futuras.txt` for the follow-up.

### Running on the real CM5

After `build_linux.sh` produces `build/linux/*/release/bundle/`, copy the whole `bundle/` directory to the CM5 (it depends on the `.so` files alongside the binary, not just the executable itself) and run the binary inside it directly. For a kiosk-style autostart (fullscreen, no window manager chrome, launches on boot) - not implemented in this repo yet, see `mejoras_futuras.txt` - a minimal Wayland kiosk compositor (e.g. `cage`) or a systemd unit launching this binary directly on a bare framebuffer are the two most common approaches for this class of embedded touchscreen deployment; [`flutter-pi`](https://github.com/ardera/flutter-pi) (a third-party bare-metal Flutter engine embedder for Raspberry Pi, running without any window system at all) is a leaner alternative worth evaluating later, but it builds against the Flutter engine directly rather than through `flutter build linux`, so it would need its own separate build step, not a drop-in replacement for this one.

## 📂 Repository Structure

```text
HYDRA-UMC-DSI/
├── build.bat, build.sh              # flutter pub get + flutter build windows (dev-machine verification)
├── build_linux.sh                   # flutter build linux (the real CM5 target - run on real Linux)
├── run_dev.bat, run_dev.sh          # flutter run - desktop simulation mode
├── lib/
│   ├── main.dart                    # App entry point, ChangeNotifierProvider + login gate, fixed dark theme
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
│       ├── settings_screen.dart     # Connection info + sign out
│       └── widgets/
│           ├── joystick_pad.dart     # Jog D-pad, sized up for touch
│           ├── digital_readout.dart, status_led.dart
│           └── mjpeg_view.dart       # Hand-rolled MJPEG stream parser
├── linux/                            # GTK desktop runner - the REAL target, fixed 1280x720 window
├── windows/                          # Windows desktop runner - dev-machine verification only
├── docs/ARCHITECTURE.md
├── test/widget_test.dart
├── README.md                         # this file
└── README_spa.md / README_ita.md / README_fra.md / README_deu.md  # translations
```

## 🔗 Related Projects

This project is part of a larger robotics ecosystem by the same author (JuanenRac / Electro Hobby 3D). Worth knowing about, since a request might actually be about one of these rather than this repository:

**HYDRA-UMC platform** — the multi-robot micro-factory cell
- **[HYDRA-UMC](https://github.com/JuanenRac/HYDRA-UMC)** — the motherboard itself: Raspberry Pi CM5 host + dual-core STM32H745 real-time co-processor, orchestrating up to 8 distributed robot arms over CAN-OTA/SPI-OTA. Own hardware + firmware, GPL-3.0/CERN-OHL-S v2/CC BY-SA 4.0.
- **[HYDRA-UMC STUDIO](https://github.com/JuanenRac/HYDRA-UMC-STUDIO)** — web-based control dashboard for HYDRA-UMC: multi-robot 3D visualization, kinematics/trajectory recording, CAN-OTA flashing and testing for the whole platform. React + Vite + Three.js.
- **[HYDRA-UMC-ANDROID-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-ANDROID-CONTROL)** — Android control app for HYDRA-UMC over Wi-Fi/Bluetooth. Real, working app - full remote-control feature set, JWT auth, encrypted credential storage.
- **[HYDRA-UMC-IOS-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-IOS-CONTROL)** — iOS/iPadOS control app for HYDRA-UMC over Wi-Fi, built in Flutter (cross-platform, verifiable on Windows without a Mac; final `.ipa` packaging still needs Xcode). Real, working app - same feature set as the Android app.
- **[HYDRA-UMC-SUITE](https://github.com/JuanenRac/HYDRA-UMC-SUITE)** — desktop (Python/PySide6) swarm command center: multi-controller network discovery, live bidirectional sync, real 3D robot viewport, Photoshop-style dockable workspace. Real and working, not a placeholder.
- **[HYDRA-UMC-EDITOR-URDF](https://github.com/JuanenRac/HYDRA-UMC-EDITOR-URDF)** — desktop (Python/PySide6) graphical URDF creator/editor for this project's own model catalog: pulls source files from GitHub or a local folder, validates DOF feasibility, edits color/scale/kinematics with a live 3D preview, and pushes the finished result to a running STUDIO server. Real and working, not a placeholder.
- **HYDRA-UMC-DSI** *(this repository)* — native Flutter touch UI for HYDRA-UMC's own 5"/7" DSI touchscreen (1280×720, same resolution at both sizes) on the Compute Module 5, controlling this same server directly from the board. Real, working scaffold with all 6 catalog screens connected to the live server; real Linux target build not yet run on real hardware (Windows-only working environment - see README's own "Building" section).

**URTC platform** — the tool head controller every HYDRA-UMC robot arm carries
- **[URTC](https://github.com/JuanenRac/URTC)** — Universal Robot Tool Controller: STM32F303-based CAN bus tool head controller, 25 fully-implemented tool profiles, CAN-OTA firmware update.
- **[URTC Flasher](https://github.com/JuanenRac/URTC-FLASHER)** — desktop CAN-OTA + full-chip SWD/JTAG flashing tool for URTC boards (Windows/Linux).
- **[URTC Tester](https://github.com/JuanenRac/URTC-TESTER)** — desktop live CAN-bus diagnostic tool for URTC boards, one panel per tool profile (Windows/Linux).
- **[URTC Web Studio](https://github.com/JuanenRac/URTC-WEB-STUDIO)** — browser-based alternative to the 2 desktop tools above (Web Serial API + SLCAN), no local install needed.

---

## 👤 Author

**JuanenRac** (Electro Hobby 3D)
📧 electrohobby3d@gmail.com
📺 youtube.com/@electrohobby3d

---

## 📜 License

GNU General Public License v3.0 (GPL-3.0) for the source code - see [`LICENSE`](LICENSE).

The documentation (this README and its own translations - `README_spa.md`, `README_ita.md`, `README_fra.md`, `README_deu.md`) is available under **Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)**. Full text at https://creativecommons.org/licenses/by-sa/4.0/.
