#!/usr/bin/env python3
# =============================================================================
# HYDRA-UMC - tools/sync_ui_spec.py
# Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
# GPL-3.0-or-later - see LICENSE
# =============================================================================
"""Keeps docs/ui/ the same as the screen data of the firmware interface in the HYDRA-UMC repository (src/ui_h757/spec).

    python tools/sync_ui_spec.py --check [folder]   exit 1 when a file differs; with no HYDRA-UMC next to this repository it says so and exits 0
    python tools/sync_ui_spec.py --apply [folder]   copy the files here

The data of the screens and of the eight languages of the display interface lives in HYDRA-UMC; the app reads this copy and test/ui_spec_parity_test.dart checks it against
the screens and the translations of the app. Evidence: simulator (file comparison)."""
from __future__ import annotations

import argparse
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FILES = ("ui_spec.json", "ui_spec.schema.json", "i18n.json")
DEFAULT_SOURCE = ROOT.parent / "HYDRA-UMC" / "src" / "ui_h757" / "spec"


def _same(first: Path, second: Path) -> bool:
    return first.read_bytes().replace(b"\r\n", b"\n") == second.read_bytes().replace(b"\r\n", b"\n")


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("folder", nargs="?", type=Path, default=DEFAULT_SOURCE)
    options = parser.parse_args(argv)
    if options.check == options.apply:
        parser.error("give exactly one of --check and --apply")
    if not options.folder.is_dir():
        print(f"SYNC_UI_SPEC=SKIP no {options.folder} next to this repository")
        return 0
    target = ROOT / "docs" / "ui"
    stale = [name for name in FILES if not (target / name).is_file() or not _same(options.folder / name, target / name)]
    if options.apply:
        target.mkdir(parents=True, exist_ok=True)
        for name in FILES:
            shutil.copyfile(options.folder / name, target / name)
        print("SYNC_UI_SPEC=APPLIED", ", ".join(FILES))
        return 0
    for name in stale:
        print(f"STALE: docs/ui/{name} differs from the display interface data (run tools/sync_ui_spec.py --apply)")
    print("SYNC_UI_SPEC=" + ("FAIL" if stale else "PASS"))
    return 1 if stale else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
