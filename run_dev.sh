#!/usr/bin/env bash
# =============================================================================
# HYDRA-UMC DSI (Flutter) - run_dev.sh
# Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
# GPL-3.0 - see LICENSE
#
# Desktop simulation mode: runs this app live against a real (or locally
# running) HYDRA-UMC STUDIO server, in a normal resizable desktop window,
# without needing the real CM5 + DSI touchscreen hardware on hand. This is
# the fast day-to-day dev loop (hot reload works normally) - build.sh/
# build_linux.sh are for producing a real standalone binary.
# =============================================================================

echo "============================================================================="
echo "HYDRA-UMC DSI (Flutter) - run_dev.sh"
echo "Runs this app in desktop simulation mode against a real or local HYDRA-UMC"
echo "STUDIO server (hot-reload dev loop - stays running until closed)."
echo "Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>"
echo "GPL-3.0 - see LICENSE"
echo "============================================================================="
echo

set -euo pipefail

if ! command -v flutter >/dev/null 2>&1; then
    echo "[ERROR] flutter was not found on PATH. Install the Flutter SDK" >&2
    echo "        (https://docs.flutter.dev/get-started/install) and add its" >&2
    echo "        bin/ directory to PATH, then re-run this script." >&2
    read -p "Press Enter to close this window..."
    exit 1
fi

# -d windows on a Windows dev machine, -d linux on a real Linux machine -
# `flutter devices` lists what's actually available; this picks whichever
# desktop target this OS supports, since this app has no android/ios/web
# platform folder to accidentally target instead.
if [[ "$(uname -s)" == "Linux" ]]; then
    TARGET="linux"
else
    TARGET="windows"
fi

echo "Starting HYDRA-UMC DSI in desktop simulation mode (-d $TARGET)..."
echo "Point it at a real or local HYDRA-UMC STUDIO server from the login screen"
echo "(cd HYDRA-UMC-STUDIO && npm run dev, then 127.0.0.1:3000 here)."
flutter run -d "$TARGET"
