#!/usr/bin/env bash
# =============================================================================
# HYDRA-UMC DSI (Flutter) - build.sh
# Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
# GPL-3.0 - see LICENSE
#
# Builds the Windows desktop target - the only target this repo can
# actually produce a runnable binary for on a Windows machine without a
# real Linux toolchain (linux/ and windows/ are the only 2 platforms
# configured in this repo; see build_linux.sh for the real CM5/Linux
# target, which must be run on an actual Linux machine - it cannot run
# from this script on Windows). Runs under Git Bash/WSL on the same
# Windows machine `flutter build windows` itself requires - this is a
# bash-shell convenience wrapper, matching HYDRA-UMC-IOS-CONTROL's own
# build.sh for the same reason (verifying app logic without the real
# target's toolchain on hand).
# =============================================================================

echo "============================================================================="
echo "HYDRA-UMC DSI (Flutter) - build.sh"
echo "Builds the Windows desktop target (dev-machine verification build - bumps"
echo "the app version, then runs flutter build windows)."
echo "Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>"
echo "GPL-3.0 - see LICENSE"
echo "============================================================================="
echo

set -euo pipefail

# Always pause before this window closes - whether the build below succeeds
# or fails - so a double-click launch doesn't flash a closed console before
# any output can be read. Runs on every exit path (normal or `exit`) because
# it's a trap, not something duplicated at each individual exit point.
_pause_on_exit() {
    local status=$?
    echo
    if [ "$status" -eq 0 ]; then
        echo "Build finished successfully."
    else
        echo "Build FAILED (exit code $status)."
    fi
    read -n 1 -s -r -p "Press any key to close this window..."
    echo
}
trap _pause_on_exit EXIT

if ! command -v flutter >/dev/null 2>&1; then
    echo "[ERROR] flutter was not found on PATH. Install the Flutter SDK" >&2
    echo "        (https://docs.flutter.dev/get-started/install) and add its" >&2
    echo "        bin/ directory to PATH, then re-run this script." >&2
    exit 1
fi

echo "[1/3] flutter pub get"
flutter pub get

echo "[2/3] dart run tool/bump_version.dart"
dart run tool/bump_version.dart

echo "[3/3] flutter build windows"
flutter build windows

echo
echo "Build complete: build/windows/x64/runner/Release/hydra_umc_dsi.exe"
echo "(Windows build - development/verification only. For the real CM5"
echo " target, run build_linux.sh on an actual Linux machine.)"
