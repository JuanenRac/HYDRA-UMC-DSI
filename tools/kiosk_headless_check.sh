#!/usr/bin/env bash
# =============================================================================
# HYDRA-UMC-DSI - tools/kiosk_headless_check.sh
# Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
# GPL-3.0-or-later - see LICENSE
# =============================================================================
# Run inside a Debian trixie container by .github/workflows/kiosk-headless.yml (the repository is mounted read-only at /work): cage and weston on a virtual screen.
# It needs no screen, no GPU and no seat. Prints one line per check and exits 1 when one fails.
set -uo pipefail
FAIL=0
ok() { echo "PASS  $*"; }
bad() { echo "FAIL  $*"; FAIL=1; }

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq >/dev/null
apt-get install -y -qq --no-install-recommends cage weston systemd udev wayland-utils >/dev/null 2>&1 || { echo "FAIL  could not install cage, weston and systemd"; exit 1; }
echo "release: $(. /etc/os-release; echo "$PRETTY_NAME")  cage: $(dpkg-query -W -f='${Version}' cage)  weston: $(dpkg-query -W -f='${Version}' weston)"

export XDG_RUNTIME_DIR=/tmp/xdg
mkdir -m 0700 -p "$XDG_RUNTIME_DIR"

# 1. cage on the headless backend runs one client fullscreen and leaves when the client does (what the unit relies on).
export WLR_BACKENDS=headless WLR_RENDERER=pixman WLR_LIBINPUT_NO_DEVICES=1 WLR_HEADLESS_OUTPUTS=1
CLIENT=/usr/bin/weston-simple-shm
if [ ! -x "$CLIENT" ]; then CLIENT="$(command -v weston-simple-shm || true)"; fi
if [ -z "$CLIENT" ] || [ ! -x "$CLIENT" ]; then apt-get install -y -qq --no-install-recommends weston-simple-shm >/dev/null 2>&1 || true; CLIENT="$(command -v weston-simple-shm || true)"; fi
if [ -n "$CLIENT" ]; then
  timeout 20 cage -- timeout 4 "$CLIENT" >/tmp/cage.log 2>&1
  code=$?
  if [ "$code" -eq 0 ] || [ "$code" -eq 124 ]; then ok "cage started a fullscreen client on the headless backend and exited ($code)"; else bad "cage exited with $code"; tail -n 15 /tmp/cage.log; fi
else
  # No demo client in this release: a shell is not a Wayland client, so only the start-up of the compositor is checked.
  timeout 5 cage -- sleep 2 >/tmp/cage.log 2>&1; code=$?
  if grep -qiE "wl_display|failed|cannot" /tmp/cage.log; then bad "cage reported an error"; tail -n 15 /tmp/cage.log; else ok "cage started and ran a command on the headless backend ($code); no Wayland demo client in this release"; fi
fi
unset WLR_BACKENDS WLR_RENDERER WLR_LIBINPUT_NO_DEVICES WLR_HEADLESS_OUTPUTS

# 2. weston headless at the size of the panel; its output is read back with wayland-info.
weston --backend=headless --width=1280 --height=800 --socket=wl-panel --idle-time=0 >/tmp/weston.log 2>&1 &
WPID=$!
for _ in $(seq 1 30); do [ -S "$XDG_RUNTIME_DIR/wl-panel" ] && break; sleep 0.5; done
if [ -S "$XDG_RUNTIME_DIR/wl-panel" ]; then
  ok "weston headless is listening on its socket"
  if command -v wayland-info >/dev/null 2>&1; then
    if WAYLAND_DISPLAY=wl-panel wayland-info 2>/dev/null | grep -qE "width: 1280 px, height: 800 px"; then ok "weston reports the output at 1280x800"; else bad "weston did not report a 1280x800 output"; WAYLAND_DISPLAY=wl-panel wayland-info 2>&1 | head -n 20; fi
  else
    echo "SKIP  wayland-info is not installed"
  fi
else
  bad "weston headless did not open its socket"; tail -n 15 /tmp/weston.log
fi
kill "$WPID" 2>/dev/null || true; wait "$WPID" 2>/dev/null || true

# 3. the udev rule of the backlight is read by udevadm.
if udevadm verify --help >/dev/null 2>&1; then
  if udevadm verify /work/kiosk/90-hydra-dsi-backlight.rules >/tmp/udev.log 2>&1; then ok "udevadm verify accepts the backlight rule"; else bad "udevadm verify rejects the backlight rule"; cat /tmp/udev.log; fi
else
  echo "SKIP  this udevadm has no verify command"
fi

# 4. the unit: systemd-analyze reads every directive (the program it starts is not in the container, so that warning is expected).
cp /work/systemd/hydra-umc-dsi.service /tmp/hydra-umc-dsi.service
systemd-analyze verify /tmp/hydra-umc-dsi.service >/tmp/verify.log 2>&1
if grep -qiE "unknown (key|lvalue|section)|unknown assignment|invalid|failed to parse" /tmp/verify.log; then bad "systemd-analyze found a bad directive"; cat /tmp/verify.log; else ok "systemd-analyze reads every directive of the panel unit"; fi
sed 's/^/      /' /tmp/verify.log | head -n 8

echo "evidence=simulator (virtual screen, no GPU, no seat, no DSI panel)"
exit "$FAIL"
