#!/usr/bin/env python3
# =============================================================================
# HYDRA-UMC-DSI - tools/sync_sdk_answers.py
# Copyright (C) 2026 JuanenRac (Electro Hobby 3D)
# GPL-3.0-or-later - see LICENSE
# =============================================================================
"""Keeps test/fixtures/server-answers.json identical to the one the SDK generates from the server inventory.

    python tools/sync_sdk_answers.py            # copy the SDK file next to this repository over the vendored one
    python tools/sync_sdk_answers.py --check    # fail when the vendored copy differs; skipped when the SDK is not next to this repository

The tests of the app replay these answers against its models (test/server_answers_test.dart), so what the server may answer is described once, in the SDK.
"""
from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VENDORED = ROOT / "test" / "fixtures" / "server-answers.json"
SOURCE = ROOT.parent / "HYDRA-UMC-SDK" / "conformance" / "app-fixtures" / "v1" / "server-answers.json"


def _text(path: Path) -> bytes:
    return path.read_bytes().replace(b"\r\n", b"\n")


def main(argv: list[str]) -> int:
    if not SOURCE.is_file():
        print("SKIP: HYDRA-UMC-SDK is not next to this repository (or has no app-fixtures yet)")
        return 0
    if "--check" in argv:
        if not VENDORED.is_file() or _text(VENDORED) != _text(SOURCE):
            print("FAIL: test/fixtures/server-answers.json differs from the SDK file; run python tools/sync_sdk_answers.py", file=sys.stderr)
            return 1
        print("PASS: the vendored server answers equal the SDK file")
        return 0
    VENDORED.parent.mkdir(parents=True, exist_ok=True)
    VENDORED.write_bytes(SOURCE.read_bytes())
    print("copied the SDK server answers")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
