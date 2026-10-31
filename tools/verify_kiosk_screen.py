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
UNIT = ROOT / "kiosk" / "hydra-umc-dsi.service"
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


if __name__ == "__main__":
    unittest.main()
