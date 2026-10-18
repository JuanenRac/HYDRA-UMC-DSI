# Contributing to HYDRA-UMC-DSI 🖥️

## Technology Stack
- **Language**: Dart / Flutter.
- **Platform**: Linux (Wayland via Cage).

## Guidelines
1. **Touch Targets**: Buttons must be at least 48x48 logical pixels for industrial touchscreens.
2. **Resources**: Avoid heavy WebView embeds; use native Flutter painters for 3D visuals.
3. **Persistence**: Session tokens go through `AuthPrefs` into the platform's secure storage (`flutter_secure_storage`), never into `shared_preferences`; only the host, the port and the language live there.
