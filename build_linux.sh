#!/usr/bin/env bash
# =============================================================================
# HYDRA-UMC DSI (Flutter) - build_linux.sh
# Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
# GPL-3.0 - see LICENSE
#
# Builds the REAL deployment target: a Linux GTK desktop binary meant to
# run on the HYDRA-UMC's own Compute Module 5, driving its 5"/7" DSI
# touchscreen (1280x720, fixed - see linux/runner/my_application.cc).
#
# This script must be run ON a real Linux machine (the CM5 itself, or any
# Linux dev box/VM) - it CANNOT run on the Windows machine this repo was
# authored on, which has no Linux build toolchain at all (confirmed via
# `wsl --status`: no WSL distro installed here). `flutter build windows`
# (build.sh/build.bat) is used instead on that machine purely as a smoke
# test of this app's own Dart logic (analyze/build/test all pass there) -
# it does not exercise this file or the linux/ platform folder at all.
#
# Prerequisites on the target Linux machine (Debian/Raspberry Pi OS
# package names - adjust for other distros):
#   sudo apt install clang cmake ninja-build pkg-config \
#       libgtk-3-dev liblzma-dev libstdc++-12-dev
#   (see https://docs.flutter.dev/platform-integration/linux/building
#   for the authoritative, up-to-date list)
# =============================================================================
set -euo pipefail

if ! command -v flutter >/dev/null 2>&1; then
    echo "[ERROR] flutter was not found on PATH. Install the Flutter SDK" >&2
    echo "        (https://docs.flutter.dev/get-started/install) and add its" >&2
    echo "        bin/ directory to PATH, then re-run this script." >&2
    exit 1
fi

echo "[1/3] flutter pub get"
flutter pub get

echo "[2/3] flutter config --enable-linux-desktop"
flutter config --enable-linux-desktop >/dev/null

echo "[3/3] flutter build linux"
flutter build linux

echo
echo "Build complete: build/linux/*/release/bundle/hydra_umc_dsi"
echo "Copy the whole bundle/ directory to the CM5 and run the binary inside"
echo "it directly (it depends on the .so files alongside it) - see"
echo "README.md's own 'Running on the real CM5' section for the kiosk"
echo "autostart setup (fullscreen, no window manager chrome)."
