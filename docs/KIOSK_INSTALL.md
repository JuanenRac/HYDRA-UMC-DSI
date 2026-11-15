# Installing the app as the kiosk of the Compute Module 5

The DSI app is the one local-screen kiosk of the Compute Module. It runs as the systemd unit `hydra-umc-dsi.service` (`systemd/hydra-umc-dsi.service`), started on `tty1` through `cage`, a Wayland compositor that shows exactly one fullscreen program. Nothing here has run on a Compute Module yet: see `docs/BENCH_TESTS.md`.

## What the unit does

- Starts only when the setting `HYDRA_LOCAL_SCREEN` is `dsi` (`/etc/hydra-umc/local-screen.conf`); for `hdmi` (the default) or `none` the start is skipped without a failure, so it never takes `tty1` from the HDMI kiosk of HYDRA-UMC-OS.
- Runs as the account `hydra-dsi` (no login shell, groups `video`, `render`, `input`), never as root.
- Restarts after a crash or after the screen is restarted from the System tab, with a limit: at most 5 starts in 5 minutes (`StartLimitBurst`, `StartLimitIntervalSec`), then it stays failed and `journalctl -u hydra-umc-dsi` says why.
- Hardening: no new privileges, no capabilities, private `/tmp`, read-only `/usr` and `/etc` (`ProtectSystem=full`), no access to the homes, no kernel modules or logs, only the address families the app uses (`AF_NETLINK` stays for the mDNS discovery), a memory ceiling. The state of the app lives in `/var/lib/hydra-dsi`.
- Holds no secret. The sign-in of the operator is kept by the app in the keyring of its account.

## Settings in files, none in the code

| File | Purpose |
|------|---------|
| `/etc/hydra-umc/local-screen.conf` | Which local screen is used: `dsi`, `hdmi` or `none`. |
| `/etc/hydra-umc-dsi/dsi.conf` | Every tunable of the panel (a directory of the panel alone; the file of `/etc/hydra-umc/dsi.conf` is copied there once, else it is created from `kiosk/dsi.conf.example`; never overwritten). |
| `/etc/hydra-umc/dsi.env` | Optional. `HYDRA_DSI_APP=/path/to/hydra_umc_dsi` to run a build in another place; the default is `/opt/hydra-umc-dsi/bundle/hydra_umc_dsi`. No secrets. |

## Steps (on the Compute Module, as root)

1. Build `flutter build linux --release` for the board and copy the whole `bundle/` folder (the program and its `.so` files) to `/opt/hydra-umc-dsi/bundle/`.
2. Install `cage` (`apt install cage`).
3. Run `sudo kiosk/install_kiosk.sh --screen dsi`. It saves the choice, creates the account, the settings file and the backlight rule, installs `systemd/hydra-umc-dsi.service`, takes `tty1` back from its getty and enables the unit.
4. Reboot, or `systemctl start hydra-umc-dsi.service`. Logs: `journalctl -u hydra-umc-dsi.service -f`.

To go back to the HDMI kiosk run `HYDRA-UMC-OS/provisioning/install_kiosk.sh --screen hdmi`; it switches this unit off.

## Registry of services

The manifest `hydra-umc.project.json` declares `"service": {"systemd_unit": "hydra-umc-dsi.service"}`. The app is a client and listens on no port, so the block has no `port` and no `health_path`.

## Where the settings file lives

The panel runs as the account `hydra-dsi`, which cannot enter the shared `/etc/hydra-umc` (mode 0750, group of the agent). The app treats a settings file it cannot read as no file, so a file kept there would be ignored without a word (the defaults, with every optional feature off). The unit therefore asks systemd for a directory of its own, `/etc/hydra-umc-dsi` (`ConfigurationDirectory=`, mode 0750), and sets `HYDRA_DSI_CONFIG=/etc/hydra-umc-dsi/dsi.conf`. `kiosk/dsi_config.sh` (installed as `/opt/hydra-umc-dsi/dsi_config.sh`) has two commands: `prepare`, run as root by the first `ExecStartPre`, makes the directory mode 0750 with the group of the account and copies the file of the earlier place (`/etc/hydra-umc/dsi.conf`) once, never overwriting and never deleting; `check`, run as the account by the second `ExecStartPre`, refuses to start (exit 2, the reason in the journal) when the directory cannot be entered or a file that is there cannot be read; no file at all is fine. The installer runs `prepare` and then `check` as the account (`runuser -u hydra-dsi`) before it installs the unit, and ends with status 4 and the line `DSI_CONFIG=REFUSED` when the account cannot read the file. The shared `/etc/hydra-umc` is never changed. `local-screen.conf` and `dsi.env` stay there: systemd reads them as root.
