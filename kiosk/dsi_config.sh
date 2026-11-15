#!/bin/sh
# =============================================================================
# HYDRA-UMC DSI (Flutter) - kiosk/dsi_config.sh
# Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
# GPL-3.0-or-later - see LICENSE
# =============================================================================
# Where the settings file of the panel lives and whether the account of the panel can read it.
#
# The panel runs as its own account (hydra-dsi), which cannot enter the shared /etc/hydra-umc (mode 0750, group of the agent). A settings file kept there is
# silently ignored by the app (an unreadable file means the defaults), so the unit names a directory of its own, /etc/hydra-umc-dsi (ConfigurationDirectory=),
# and the shared directory is never changed. Two commands, run by the unit and by the installer (installed as /opt/hydra-umc-dsi/dsi_config.sh):
#
#   prepare   as root: make the directory mode 0750 owned by root with the group of the panel account, and copy the settings file of the earlier place
#             (/etc/hydra-umc/dsi.conf) into it once; never overwrites, never deletes the old file. Exit 0 whether it copied, kept or found nothing.
#   check     as the panel account: exit 0 when the directory can be entered and the settings file, if there is one, can be read; exit 2 with the reason
#             otherwise. No file at all is fine (the defaults are the conservative ones); a file that exists and cannot be read is not.
#
# Settings, for the tests: HYDRA_DSI_CONFIG_DIR, HYDRA_DSI_LEGACY_CONF, HYDRA_DSI_USER.
DSI_CONFIG_DIR="${HYDRA_DSI_CONFIG_DIR:-/etc/hydra-umc-dsi}"
DSI_CONFIG_FILE="$DSI_CONFIG_DIR/dsi.conf"
DSI_LEGACY_CONF="${HYDRA_DSI_LEGACY_CONF:-/etc/hydra-umc/dsi.conf}"
DSI_ACCOUNT="${HYDRA_DSI_USER:-hydra-dsi}"

dsi_config_prepare() {
  case "$DSI_CONFIG_DIR" in
    /etc/hydra-umc | /etc/hydra-umc/) echo "dsi_config: $DSI_CONFIG_DIR is the shared directory: it is never changed." >&2; return 2 ;;
  esac
  mkdir -p "$DSI_CONFIG_DIR" || return 2
  chmod 0750 "$DSI_CONFIG_DIR" || return 2
  if [ "$(id -u)" -eq 0 ] && getent group "$DSI_ACCOUNT" >/dev/null 2>&1; then
    chown "root:$DSI_ACCOUNT" "$DSI_CONFIG_DIR" || return 2
  fi
  if [ -e "$DSI_CONFIG_FILE" ]; then
    echo "dsi_config: kept $DSI_CONFIG_FILE"
  elif [ -f "$DSI_LEGACY_CONF" ]; then
    cp -- "$DSI_LEGACY_CONF" "$DSI_CONFIG_FILE" || return 2
    chmod 0640 "$DSI_CONFIG_FILE" || return 2
    if [ "$(id -u)" -eq 0 ] && getent group "$DSI_ACCOUNT" >/dev/null 2>&1; then
      chown "root:$DSI_ACCOUNT" "$DSI_CONFIG_FILE" || return 2
    fi
    echo "dsi_config: migrated $DSI_LEGACY_CONF to $DSI_CONFIG_FILE (the old file stays)"
  else
    echo "dsi_config: nothing to migrate ($DSI_CONFIG_FILE)"
  fi
}

dsi_config_check() {
  if [ -d "$DSI_CONFIG_DIR" ] && [ ! -x "$DSI_CONFIG_DIR" ]; then
    echo "dsi_config: the directory $DSI_CONFIG_DIR cannot be entered by this account (the settings of the panel would be ignored): give it to root with the group $DSI_ACCOUNT, mode 0750." >&2
    return 2
  fi
  if [ -e "$DSI_CONFIG_FILE" ] && [ ! -r "$DSI_CONFIG_FILE" ]; then
    echo "dsi_config: the file $DSI_CONFIG_FILE cannot be read by this account (the settings of the panel would be ignored): give it to root with the group $DSI_ACCOUNT, mode 0640." >&2
    return 2
  fi
  if [ -e "$DSI_CONFIG_FILE" ]; then
    echo "dsi_config: $DSI_CONFIG_FILE is readable by this account"
  else
    echo "dsi_config: there is no $DSI_CONFIG_FILE: the panel runs with its defaults"
  fi
}

# Run as a command (the unit and the installer); sourced, it only defines the functions.
case "${0##*/}" in
  dsi_config.sh)
    case "${1:-}" in
      prepare) dsi_config_prepare ;;
      check) dsi_config_check ;;
      *) echo "usage: dsi_config.sh prepare|check" >&2; exit 64 ;;
    esac
    ;;
esac
