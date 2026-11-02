# Bench tests

Every test below is **not executed**. The panel logic, the settings file and the unit text are covered by the Dart tests and by the text checks of the CI; none of it has run on a Compute Module 5 with a DSI panel. Write a result only after a person ran the step.

## What the software already covers (no panel needed)

- `python tools/hydra_project_tool.py test` runs the Dart tests (login, reservations, take control, idle lock, settings file, redraw counts) and the text checks of the kiosk files.
- `tools/verify_kiosk_screen.py` reads the kiosk files and checks that the unit, the installer and the udev rule agree with each other. It does not run systemd.

## Setup

- A Compute Module 5 with the DSI panel, the HYDRA-UMC server running on the same board and the panel installed with `kiosk/install_kiosk.sh`.
- The settings file `/etc/hydra-umc/dsi.conf` created by the installer (every key is documented in `kiosk/dsi.conf.example`).
- One administrator account and one operator account on the server.

## Steps

| # | Step | Expected result | Result |
|---|------|-----------------|--------|
| 1 | Run the installer and look at `id hydra-dsi` and `systemctl show hydra-umc-dsi -p User`. | The account exists with groups `video`, `render`, `input`; the unit runs as that user, not as root. | not executed |
| 2 | Start the unit and read `systemctl status` and `journalctl -u hydra-umc-dsi`. | The unit starts with `NoNewPrivileges`, a private `/tmp` and a read-only system; if the image refuses a directive (cage, logind, PAM) the log names it. Record which one. | not executed |
| 3 | With `appliance = on`, restart the unit. | The panel connects to `127.0.0.1`, does not scan the network and uses the saved session. | not executed |
| 4 | With `virtual_keyboard = on`, open the sign-in screen and touch each field. | The keyboard appears and types into the field touched last. | not executed |
| 5 | As a member of `video`, write a value to `/sys/class/backlight/*/brightness`; then let the panel dim and wake it. | The udev rule allows the write; dimming and waking change the real brightness and the time-of-day schedule does not undo them. | not executed |
| 6 | Leave the panel without touch for the idle time, then type a wrong and a right PIN. | The panel dims, shows the saver, locks; wrong tries lock the pad for longer each round; the right PIN unlocks. The STOP stays reachable. | not executed |
| 7 | Reserve a robot as an operator, then try to take control from another account. | An operator is refused; an administrator is asked to confirm and then takes control. | not executed |
| 8 | Restart the Compute Module and the unit and read the saved session on the keyring. | The session survives the restart; if the keyring is unreachable under the service the log says so. | not executed |
| 9 | Look at the full-screen state and the orientation on the panel. | The window fills the panel in the chosen orientation; record any title bar or close button that is still visible. | not executed |

## What this bench cannot show

Touch accuracy, panel brightness range and the behaviour of the compositor depend on the panel and the operating-system image. Record the panel model and the image version with every result.
