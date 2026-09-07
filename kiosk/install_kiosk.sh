#!/usr/bin/env bash
# =============================================================================
# HYDRA-UMC DSI (Flutter) - kiosk/install_kiosk.sh
# Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
# GPL-3.0 - see LICENSE
#
# Installs and enables hydra-umc-dsi.service (this directory) on a real
# Linux machine - the CM5 itself. Run ON that machine, as root, AFTER
# build_linux.sh has produced build/linux/*/release/bundle/ and that
# bundle/ directory has been copied to /opt/hydra-umc-dsi/bundle/ (see
# README.md "Running on the real CM5"). Does not install `cage` itself -
# the exact package name/availability varies by distro image, so this
# script only checks it's already on PATH and tells you what's missing
# rather than guessing a package manager invocation that might be wrong
# for whatever image the CM5 is actually running.
#
# HONESTY NOTE: same as hydra-umc-dsi.service's own header comment - never
# actually run against a real CM5 or any other Linux box, no Linux machine
# is available in the environment this was written in. Treat the first
# real run as the first real test, not a formality.
# =============================================================================
set -euo pipefail

BUNDLE_DIR="/opt/hydra-umc-dsi/bundle"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE_SRC="$SCRIPT_DIR/hydra-umc-dsi.service"

if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root (sudo ./install_kiosk.sh)." >&2
  exit 1
fi

if [ ! -x "$BUNDLE_DIR/hydra_umc_dsi" ]; then
  echo "Expected an executable at $BUNDLE_DIR/hydra_umc_dsi - copy build/linux/*/release/bundle/'s" >&2
  echo "full contents there first (the binary needs the .so files alongside it, not just itself)." >&2
  exit 1
fi

if ! command -v cage >/dev/null 2>&1; then
  echo "cage not found on PATH - install a Wayland kiosk compositor package providing it first" >&2
  echo "(e.g. 'apt install cage' on Debian/Raspberry Pi OS derivatives) and re-run this script." >&2
  exit 1
fi

install -m 644 "$SERVICE_SRC" /etc/systemd/system/hydra-umc-dsi.service
systemctl daemon-reload

# tty1's own getty would otherwise fight this service for the same
# terminal - disable it so cage owns tty1 outright. Non-fatal if it's
# already disabled or doesn't exist on this image.
systemctl disable --now getty@tty1.service 2>/dev/null || true

systemctl enable hydra-umc-dsi.service

echo "Installed and enabled. Reboot the CM5, or run 'systemctl start hydra-umc-dsi.service' now, to launch the kiosk."
echo "Logs: journalctl -u hydra-umc-dsi.service -f"
