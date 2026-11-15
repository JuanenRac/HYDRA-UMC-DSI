#!/usr/bin/env python3
# =============================================================================
# HYDRA-UMC DSI - Kiosk installer: which local screen the CM5 drives
# Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
# GPL-3.0-or-later - see LICENSE
# =============================================================================
"""kiosk/install_kiosk.sh installs the app on the DSI screen only when the setting HYDRA_LOCAL_SCREEN is dsi, so it never
takes tty1 from the HDMI kiosk of HYDRA-UMC-OS. The block that reads the setting runs in bash against stubs of
systemctl and install in a temporary folder, the unit is checked as text and its start condition is run as the shell
would run it: nothing is installed, no root is needed. None of this has run on a CM5."""
from __future__ import annotations

import os
import re
import shutil
import stat
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
INSTALLER = ROOT / "kiosk" / "install_kiosk.sh"
UNIT = ROOT / "systemd" / "hydra-umc-dsi.service"
LIBRARY = ROOT / "kiosk" / "local_screen.sh"
BASH = shutil.which("bash")


def posix(path: Path) -> str:
    return re.sub(r"^([A-Za-z]):", lambda m: "/" + m.group(1).lower(), path.as_posix()) if os.name == "nt" else path.as_posix()


def block(text: str, name: str) -> str:
    return text.split(f"# --- {name} begin")[1].split(f"# --- {name} end")[0]


class StaticTests(unittest.TestCase):
    def test_the_unit_starts_only_for_the_dsi_screen(self) -> None:
        text = UNIT.read_text(encoding="utf-8")
        self.assertIn("EnvironmentFile=-/etc/hydra-umc/local-screen.conf", text)
        self.assertIn("""ExecCondition=/bin/sh -c 'test "$${HYDRA_LOCAL_SCREEN:-hdmi}" = dsi'""", text)
        self.assertLess(text.index("ExecCondition="), text.index("ExecStart="))

    def test_the_installer_refuses_unless_the_screen_is_dsi(self) -> None:
        text = INSTALLER.read_text(encoding="utf-8")
        self.assertIn('if [ "$SCREEN" != dsi ]; then', text)
        self.assertLess(text.index("# --- local screen begin"), text.index("systemctl daemon-reload"))
        self.assertLess(text.index("# --- local screen end"), text.index('install -m 644 "$SERVICE_SRC"'))

    def test_the_panel_does_not_run_as_root_and_the_unit_is_hardened(self) -> None:
        text = UNIT.read_text(encoding="utf-8")
        directives = {line.split("=", 1)[0]: line.split("=", 1)[1] for line in text.splitlines() if re.match(r"^[A-Za-z]+=", line)}
        self.assertEqual(directives["User"], "hydra-dsi")
        self.assertNotIn("root", directives["User"])
        for name in ("NoNewPrivileges", "PrivateTmp", "ProtectHome", "ProtectKernelModules", "ProtectKernelLogs", "RestrictSUIDSGID", "LockPersonality"):
            self.assertEqual(directives[name], "yes", name)
        self.assertEqual(directives["CapabilityBoundingSet"], "")
        self.assertIn("AF_NETLINK", directives["RestrictAddressFamilies"], "the mDNS discovery needs netlink")
        self.assertIn("video", directives["SupplementaryGroups"])
        self.assertIn("HYDRA_DSI_CONFIG=/etc/hydra-umc-dsi/dsi.conf", text)
        self.assertEqual(directives["Restart"], "always", "the reboot button of the screen relies on the supervisor starting the app again")
        self.assertIn("StartLimitBurst=", text, "a crash loop must stop after a few starts")
        self.assertIn("StartLimitIntervalSec=", text)
        self.assertIn("EnvironmentFile=-/etc/hydra-umc/dsi.env", text, "the path of the app is set from a file")
        self.assertIn("ExecStart=/usr/bin/cage -- ${HYDRA_DSI_APP}", text)
        self.assertNotIn("Password", text, "no secret in the unit")

    def test_the_manifest_declares_the_unit_without_a_port(self) -> None:
        import json
        manifest = json.loads((ROOT / "hydra-umc.project.json").read_text(encoding="utf-8"))
        self.assertEqual(manifest["service"], {"systemd_unit": "hydra-umc-dsi.service"}, "the app serves no HTTP: no port, no health path")

    def test_the_installer_makes_the_account_the_settings_file_and_the_backlight_rule(self) -> None:
        text = INSTALLER.read_text(encoding="utf-8")
        self.assertIn('DSI_USER="hydra-dsi"', text)
        self.assertIn("useradd --system", text)
        self.assertIn('if [ ! -e "$CONF_DIR/dsi.conf" ]; then', text)
        self.assertIn("90-hydra-dsi-backlight.rules", text)
        self.assertLess(text.index("# --- panel account end"), text.index('install -m 644 "$SERVICE_SRC"'))
        self.assertLess(text.index("# --- local screen end"), text.index("# --- panel account begin"))
        rule = (ROOT / "kiosk" / "90-hydra-dsi-backlight.rules").read_text(encoding="utf-8")
        self.assertIn('SUBSYSTEM=="backlight"', rule)
        self.assertIn("chgrp video", rule)
        self.assertTrue((ROOT / "kiosk" / "dsi.conf.example").is_file())

    @unittest.skipUnless(BASH, "bash is needed")
    def test_the_scripts_have_valid_syntax(self) -> None:
        for script in (INSTALLER, LIBRARY):
            result = subprocess.run([BASH or "bash", "-n", script.as_posix()], capture_output=True, text=True, check=False)
            self.assertEqual(result.returncode, 0, result.stderr)


@unittest.skipUnless(BASH, "bash is needed")
class ConditionTests(unittest.TestCase):
    """The start condition of the unit, run as sh runs it (systemd turns $$ into $)."""

    def condition(self, value: str | None) -> int:
        line = next(line for line in UNIT.read_text(encoding="utf-8").splitlines() if line.startswith("ExecCondition="))
        command = re.search(r"-c '(.*)'$", line)
        assert command is not None
        env = {key: val for key, val in os.environ.items() if key != "HYDRA_LOCAL_SCREEN"}
        if value is not None:
            env["HYDRA_LOCAL_SCREEN"] = value
        return subprocess.run([BASH or "bash", "-c", command.group(1).replace("$$", "$")], env=env, check=False).returncode

    def test_only_dsi_lets_the_unit_start(self) -> None:
        self.assertEqual(self.condition("dsi"), 0)
        self.assertNotEqual(self.condition("hdmi"), 0)
        self.assertNotEqual(self.condition("none"), 0)
        self.assertNotEqual(self.condition(None), 0, "without a setting the screen is hdmi")
        self.assertNotEqual(self.condition(""), 0)


@unittest.skipUnless(BASH, "bash is needed")
class InstallerBlockTests(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self._tmp.cleanup)
        self.root = Path(self._tmp.name)
        self.stubs = self.root / "stubs"
        self.stubs.mkdir()
        self.log = self.root / "log.txt"
        self.systemd = self.root / "systemd"
        (self.systemd / "getty@tty1.service.d").mkdir(parents=True)
        self.autologin = self.systemd / "getty@tty1.service.d" / "hydra-umc-autologin.conf"
        self.autologin.write_text("[Service]\n", encoding="utf-8")
        self.config = self.root / "etc" / "local-screen.conf"
        stub = self.stubs / "install"
        stub.write_text('#!/usr/bin/env bash\necho "install $*" >> "$LOG"\n[[ "$1" == -d ]] && mkdir -p "${@: -1}"\nexit 0\n', encoding="utf-8")
        stub.chmod(stub.stat().st_mode | stat.S_IEXEC)

    def run_block(self, request: str = "", **variables: str) -> subprocess.CompletedProcess[str]:
        script = "set -euo pipefail\n" + block(INSTALLER.read_text(encoding="utf-8"), "local screen") + "\necho CONTINUED\n"
        env = {
            **{key: value for key, value in os.environ.items() if key != "HYDRA_LOCAL_SCREEN"},
            "PATH": f"{posix(self.stubs)}:{os.environ['PATH']}",
            "SCRIPT_DIR": posix(ROOT / "kiosk"),
            "SCREEN_REQUEST": request,
            "SYSTEMD_DIR": posix(self.systemd),
            "HYDRA_LOCAL_SCREEN_FILE": posix(self.config),
            "LOG": posix(self.log),
            **variables,
        }
        return subprocess.run([BASH or "bash", "-c", script], capture_output=True, text=True, env=env, check=False)

    def test_without_a_setting_nothing_is_installed(self) -> None:
        result = self.run_block()
        self.assertEqual(result.returncode, 3)
        self.assertNotIn("CONTINUED", result.stdout)
        self.assertIn("--screen dsi", result.stderr)
        self.assertTrue(self.autologin.exists(), "the HDMI kiosk keeps tty1")
        self.assertFalse(self.config.exists())

    def test_hdmi_and_none_install_nothing_either(self) -> None:
        for value in ("hdmi", "none"):
            result = self.run_block(HYDRA_LOCAL_SCREEN=value)
            self.assertEqual(result.returncode, 3, value)
            self.assertNotIn("CONTINUED", result.stdout)
            self.assertTrue(self.autologin.exists(), value)

    def test_a_value_that_is_not_one_of_the_three_stops_everything(self) -> None:
        for value in ("both", "ninguna", "DSI2"):
            result = self.run_block(HYDRA_LOCAL_SCREEN=value)
            self.assertEqual(result.returncode, 2, value)
            self.assertIn("hdmi, dsi or none", result.stderr)
            self.assertTrue(self.autologin.exists(), value)

    def test_screen_dsi_saves_the_choice_and_takes_tty1_from_the_hdmi_kiosk(self) -> None:
        result = self.run_block(request="dsi")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("CONTINUED", result.stdout)
        self.assertIn("HYDRA_LOCAL_SCREEN=dsi", self.config.read_text(encoding="utf-8"))
        self.assertFalse(self.autologin.exists())

    def test_the_saved_choice_is_read_back_and_a_request_beats_the_environment(self) -> None:
        self.run_block(request="dsi")
        self.assertIn("CONTINUED", self.run_block().stdout)
        self.assertIn("CONTINUED", self.run_block(request="dsi", HYDRA_LOCAL_SCREEN="hdmi").stdout)
        self.assertNotIn("CONTINUED", self.run_block(HYDRA_LOCAL_SCREEN="hdmi").stdout, "the environment beats the saved file")

    def test_screen_none_requested_here_is_refused_not_saved_as_dsi(self) -> None:
        result = self.run_block(request="none")
        self.assertEqual(result.returncode, 3)
        self.assertNotIn("dsi", self.config.read_text(encoding="utf-8") if self.config.exists() else "")


SETTINGS = ROOT / "kiosk" / "dsi_config.sh"
POSIX_USER = hasattr(os, "geteuid") and os.geteuid() != 0 and os.name != "nt"


class SettingsDirectoryStaticTests(unittest.TestCase):
    def test_the_unit_asks_systemd_for_a_directory_of_its_own_and_checks_the_file_before_the_start(self) -> None:
        text = UNIT.read_text(encoding="utf-8")
        self.assertIn("ConfigurationDirectory=hydra-umc-dsi\n", text)
        self.assertIn("ConfigurationDirectoryMode=0750\n", text)
        self.assertNotIn("ConfigurationDirectory=hydra-umc\n", text)
        lines = [line for line in text.splitlines() if line.startswith("Exec")]
        prepare = next(i for i, line in enumerate(lines) if line.endswith("dsi_config.sh prepare"))
        check = next(i for i, line in enumerate(lines) if line.endswith("dsi_config.sh check"))
        self.assertTrue(lines[prepare].startswith("ExecStartPre=+"), "the migration runs as root")
        self.assertTrue(lines[check].startswith("ExecStartPre=/"), "the check runs as the account of the panel")
        self.assertLess(prepare, check)
        self.assertLess(check, next(i for i, line in enumerate(lines) if line.startswith("ExecStart=")))

    def test_the_installer_prepares_then_asks_the_account_before_it_installs_the_unit(self) -> None:
        text = INSTALLER.read_text(encoding="utf-8")
        prepare = text.index('sh "$APP_DIR/dsi_config.sh" prepare')
        check = text.index('runuser -u "$DSI_USER" -- sh "$APP_DIR/dsi_config.sh" check')
        self.assertLess(prepare, check)
        self.assertLess(check, text.index('install -m 644 "$SERVICE_SRC"'))
        self.assertLess(check, text.index("systemctl daemon-reload"))
        self.assertIn("exit 4", text[check : check + 400])
        self.assertIn("DSI_CONFIG=REFUSED", text)

    def test_the_default_path_of_the_app_is_the_directory_of_the_panel(self) -> None:
        dart = (ROOT / "lib" / "util" / "panel_config.dart").read_text(encoding="utf-8")
        self.assertIn("defaultPath = '/etc/hydra-umc-dsi/dsi.conf'", dart)

    def test_nothing_changes_the_shared_directory(self) -> None:
        text = SETTINGS.read_text(encoding="utf-8")
        self.assertNotIn("chmod 0750 /etc/hydra-umc ", text)
        self.assertIn("/etc/hydra-umc | /etc/hydra-umc/)", text, "the shared directory is refused by name")

    @unittest.skipUnless(BASH, "bash is needed")
    def test_the_script_has_valid_syntax(self) -> None:
        result = subprocess.run([BASH or "bash", "-n", SETTINGS.as_posix()], capture_output=True, text=True, check=False)
        self.assertEqual(result.returncode, 0, result.stderr)


@unittest.skipUnless(BASH, "bash is needed")
class SettingsDirectoryTests(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self._tmp.cleanup)
        self.base = Path(self._tmp.name)
        self.directory = self.base / "etc" / "hydra-umc-dsi"
        self.legacy = self.base / "etc" / "hydra-umc" / "dsi.conf"
        self.legacy.parent.mkdir(parents=True)

    def run_script(self, command: str, **variables: str) -> subprocess.CompletedProcess[str]:
        env = {**os.environ, "HYDRA_DSI_CONFIG_DIR": posix(self.directory), "HYDRA_DSI_LEGACY_CONF": posix(self.legacy), "HYDRA_DSI_USER": "hydra-no-such-account", **variables}
        return subprocess.run([BASH or "bash", posix(SETTINGS), command], capture_output=True, text=True, env=env, check=False)

    def test_prepare_makes_the_directory_and_copies_the_earlier_file_once(self) -> None:
        self.legacy.write_text("appliance = on\n", encoding="utf-8")
        first = self.run_script("prepare")
        self.assertEqual(first.returncode, 0, first.stderr)
        self.assertIn("migrated", first.stdout)
        self.assertEqual((self.directory / "dsi.conf").read_text(encoding="utf-8"), "appliance = on\n")
        self.assertTrue(self.legacy.is_file(), "the old file is never deleted")
        if os.name != "nt":
            self.assertEqual(stat.S_IMODE(self.directory.stat().st_mode), 0o750)
            self.assertEqual(stat.S_IMODE((self.directory / "dsi.conf").stat().st_mode), 0o640)

    def test_prepare_never_overwrites_the_file_that_is_there(self) -> None:
        self.directory.mkdir(parents=True)
        (self.directory / "dsi.conf").write_text("appliance = off\n", encoding="utf-8")
        self.legacy.write_text("appliance = on\n", encoding="utf-8")
        result = self.run_script("prepare")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("kept", result.stdout)
        self.assertEqual((self.directory / "dsi.conf").read_text(encoding="utf-8"), "appliance = off\n")

    def test_prepare_with_nothing_to_migrate_succeeds_and_makes_no_file(self) -> None:
        result = self.run_script("prepare")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("nothing to migrate", result.stdout)
        self.assertFalse((self.directory / "dsi.conf").exists())

    def test_prepare_refuses_the_shared_directory(self) -> None:
        shared = self.run_script("prepare", HYDRA_DSI_CONFIG_DIR="/etc/hydra-umc")
        self.assertEqual(shared.returncode, 2)
        self.assertIn("shared directory", shared.stderr)

    def test_check_passes_without_a_file_and_says_the_panel_uses_its_defaults(self) -> None:
        result = self.run_script("check")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("defaults", result.stdout)

    def test_check_passes_with_a_readable_file(self) -> None:
        self.directory.mkdir(parents=True)
        (self.directory / "dsi.conf").write_text("appliance = on\n", encoding="utf-8")
        result = self.run_script("check")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("readable", result.stdout)

    @unittest.skipUnless(POSIX_USER, "needs a POSIX account that is not root")
    def test_check_refuses_a_file_the_account_cannot_read(self) -> None:
        self.directory.mkdir(parents=True)
        conf = self.directory / "dsi.conf"
        conf.write_text("appliance = on\n", encoding="utf-8")
        conf.chmod(0)
        self.addCleanup(conf.chmod, 0o600)
        result = self.run_script("check")
        self.assertEqual(result.returncode, 2)
        self.assertIn("cannot be read", result.stderr)

    @unittest.skipUnless(POSIX_USER, "needs a POSIX account that is not root")
    def test_check_refuses_a_directory_the_account_cannot_enter(self) -> None:
        self.directory.mkdir(parents=True)
        (self.directory / "dsi.conf").write_text("appliance = on\n", encoding="utf-8")
        self.directory.chmod(0)
        self.addCleanup(self.directory.chmod, 0o700)
        result = self.run_script("check")
        self.assertEqual(result.returncode, 2)
        self.assertIn("cannot be entered", result.stderr)

    def test_an_unknown_command_is_refused(self) -> None:
        self.assertEqual(self.run_script("erase").returncode, 64)

    def test_sourcing_the_script_only_defines_the_functions(self) -> None:
        env = {**os.environ, "HYDRA_DSI_CONFIG_DIR": posix(self.directory)}
        body = '. "' + posix(SETTINGS) + '"; type dsi_config_check >/dev/null && echo DEFINED'
        result = subprocess.run([BASH or "bash", "-c", body], capture_output=True, text=True, env=env, check=False)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("DEFINED", result.stdout)
        self.assertFalse(self.directory.exists())


if __name__ == "__main__":
    unittest.main()
