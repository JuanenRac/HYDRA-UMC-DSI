# HYDRA-UMC DSI - Architecture

**Status: real, working scaffold + core screens.** `flutter analyze` is
clean, `flutter build windows` produces a running binary, `flutter test`
passes. The real Linux target (`flutter build linux`) has not been built
on real hardware from this repo's own working environment - see "Build
verification" below for exactly what was and wasn't possible to check here.

## 1. What this app is

A native Flutter touch UI for HYDRA-UMC's own 5"/7" DSI touchscreen,
running directly on the HYDRA-UMC's Compute Module 5 - controlling the
same [HYDRA-UMC STUDIO](https://github.com/JuanenRac/HYDRA-UMC-STUDIO)
server the browser UI, SUITE, Android, and iOS clients all talk to,
without needing a browser, monitor, keyboard, or mouse attached to the CM5.
Both physical panel sizes (5" and 7") share the exact same 1280x720 pixel
resolution, so this app ships one fixed layout, not a responsive one. This
was corrected from an earlier 1280x800 assumption before this app's own code
existed.

This app is one of **two coexisting control surfaces** on the same board:
the CM5 also drives an HDMI output for a full external monitor running the
browser UI. This DSI app complements that path with a direct, always-on
touch console at the board itself - it does not replace the browser UI,
and deliberately does not try to reproduce every one of its panels (see
section 4 below for the one screen where that trade-off is most visible).

## 2. Why Flutter, and why Linux (not Kivy)

The stack decision considered two options: a Python/Kivy stack in the style of
KlipperScreen, or Flutter. Flutter was chosen for one concrete reason:
[HYDRA-UMC-IOS-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-IOS-CONTROL)
already has a complete, working Dart implementation of everything this
app also needs - the REMOTE_API.md client (`hydra_api_client.dart`,
`hydra_websocket.dart`), the state layer (`robot_view_model.dart`,
`hydra_state.dart`), and several UI patterns (jog pad, digital readouts,
status LED, MJPEG viewer) - all directly portable with zero rewrite
required, since this app runs the same language on the same framework.
A Kivy stack would have needed all of that rewritten from scratch in
Python with no existing precedent anywhere in this ecosystem. Per
[[No reference -> reuse, don't invent]], reusing the working Dart code
was the concrete, low-risk choice over introducing a brand-new toolkit.

**Correction to the record:** an earlier note (both this project's own
`chat.TXT` and the task brief that started this implementation) described
HYDRA-UMC-IOS-CONTROL as already using "a real embedded Linux target."
That was inaccurate - `HYDRA-UMC-IOS-CONTROL` has only
`ios/` and `windows/` platform folders; it has never had a `linux/` folder,
because its own real target is iOS and Windows exists there purely to
verify app logic without a Mac (see that repo's own README "Why Flutter,
not native Swift" section). This app is the first one in the ecosystem to
actually add a `linux/` platform folder, because it is the first Flutter
app here whose real deployment target genuinely is Linux (the CM5's own
OS), not a stand-in for a platform this dev machine can't build.

## 3. Wi-Fi transport - REMOTE_API.md, same contract as every other client

Identical contract to HYDRA-UMC-IOS-CONTROL's own (see that repo's own
`docs/ARCHITECTURE.md` section 2 for the endpoint-by-endpoint breakdown,
not repeated here to avoid drift) with exactly one difference: this app's
own `network/hydra_api_client.dart` sends `X-Hydra-Client: dsi` instead of
`ios`/`android`/`suite`.

**Known gap, not fixed by this app's own code:** `REMOTE_API.md` section 1
documents only `suite`, `android`, and `ios` as recognized values for that
header - a value it doesn't recognize is "never gated," meaning this app's
own discovery requests pass through unconditionally today (functionally
identical to sending no header at all). HYDRA-UMC-STUDIO's own
`SystemSettings.remoteAccess` type and its Config > Remote Access tab
would need a 4th toggle added server-side before the project owner could
disable this app's own remote access independently of the other three -
that's a change to a different repository's server code, out of scope for
this one. Tracked in the root README's own "Known Follow-ups" section.

## 4. The one screen that isn't a straight port: 3D View

`ui/three_d_screen.dart` does NOT embed HYDRA-UMC STUDIO's real Three.js
scene in a WebView the way the iOS and Android apps both do. Two
independent reasons, either sufficient on its own:

1. **`webview_flutter` ships no Linux desktop implementation at all** -
   only Android/iOS/macOS (see that package's own pub.dev "Platform
   Support" table). Embedding it would compile fine on this Windows dev
   machine but throw `MissingPluginException` the moment this screen
   opened on the real CM5 - the actual target this app ships to.
2. **A full browser engine rendering a live 3D scene is a meaningfully
   heavier runtime load** than the rest of this app combined - a real
   concern on a low-power embedded CM5 driving a touchscreen directly,
   unlike a phone/tablet with its own dedicated GPU driver stack.

Instead, this screen draws a small native, dependency-free isometric
axis/position indicator (`CustomPainter`, no 3D engine, no mesh data) for
the selected robot's live X/Y/Z - useful for an at-a-glance "where is the
tool head right now," with an explicit on-screen note pointing to the real
3D scene on this same board's HDMI-connected monitor rather than silently
shipping a degraded substitute with no explanation. See
`ui/three_d_screen.dart`'s own header comment for the full reasoning, and
the root README's own "Known Follow-ups" section for what a real native
3D renderer for this screen would need.

## 5. Horizontal touch navigation, not a phone-style bottom nav

`ui/main_screen.dart` uses a persistent horizontal bar of 6 large icon+label
tabs across the top of the fixed 1280x720 frame (Dashboard/Control/Camera/
3D View/Metrics/Settings) instead of Android/iOS's own bottom
`NavigationBar` - matching the "menu tactil horizontal similar en espiritu
a KlipperScreen" the project owner asked for in `chat.TXT` section 1/3.
Metrics is a new, dedicated tab (not present as its own screen on iOS/
Android, which fold a couple of those numbers into a corner of their own
Dashboard) since the DSI spec explicitly calls out system metrics as its
own catalog entry - see `ui/metrics_screen.dart`'s own header comment.

## 6. Real source layout

```text
lib/
├── main.dart
├── models/        server_info.dart, hydra_state.dart
├── network/       hydra_api_client.dart, hydra_websocket.dart, discovery.dart, auth_prefs.dart
├── state/         robot_view_model.dart
└── ui/            login_screen.dart, main_screen.dart, dashboard_screen.dart,
                   control_screen.dart, camera_screen.dart, three_d_screen.dart,
                   metrics_screen.dart, settings_screen.dart, widgets/
```

See the root README's own "Repository Structure" section for what each
file does - not duplicated here to avoid the 2 documents drifting apart.

## 7. Build verification - what was and wasn't actually run

This repo was authored on a Windows machine with no Linux build toolchain
available (`wsl --status` shows no WSL distro installed) - `flutter build
linux` was never actually run against this code. What WAS run for real,
on this exact codebase, before anything here was called done:

- `flutter analyze` - clean, 0 issues.
- `flutter build windows` - succeeds, produces a running
  `build/windows/x64/runner/Release/hydra_umc_dsi.exe`.
- `flutter test` - the one smoke test in `test/widget_test.dart` passes.

`flutter create --platforms=linux,windows` did generate a real `linux/`
platform folder (CMake + GTK runner code), and `linux/runner/my_application.cc`
was hand-edited for the fixed 1280x720/non-resizable window - but that
code path has only been read, not compiled, from this working environment.
Whoever runs `build_linux.sh` for the first time on a real Linux machine
(or the CM5 itself) should treat that as the actual first real build of
this platform target, not a formality - see the root README's own
"Known Follow-ups" section.

## 8. Relationship to the rest of the ecosystem

See the root [`README.md`](../README.md)'s own "Related Projects" section.
Same REMOTE_API.md contract as
[HYDRA-UMC SUITE](https://github.com/JuanenRac/HYDRA-UMC-SUITE),
[HYDRA-UMC-ANDROID-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-ANDROID-CONTROL),
and [HYDRA-UMC-IOS-CONTROL](https://github.com/JuanenRac/HYDRA-UMC-IOS-CONTROL)
(the last of which this app borrows the most Dart code from directly),
served by [HYDRA-UMC STUDIO](https://github.com/JuanenRac/HYDRA-UMC-STUDIO),
which is the human-facing side of
[HYDRA-UMC](https://github.com/JuanenRac/HYDRA-UMC) itself - the same
board this app's own binary runs on.
