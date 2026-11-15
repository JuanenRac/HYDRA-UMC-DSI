#!/usr/bin/env python3
# =============================================================================
# HYDRA-UMC-DSI - tools/sync_sdk_client.py
# Copyright (C) 2026 JuanenRac (Electro Hobby 3D)
# GPL-3.0-or-later - see LICENSE
# =============================================================================
"""Keeps lib/generated/hydra_server_client.dart identical to the client the SDK generates from the server contract.

    python tools/sync_sdk_client.py            # copy the SDK file over the vendored one
    python tools/sync_sdk_client.py --check    # fail when the vendored copy differs; skipped when the SDK is not available

The SDK is the folder named by HYDRA_UMC_SDK_DIR (the CI sets it to the pinned tag) or the HYDRA-UMC-SDK folder next to this repository.
The file is generated: it is never edited here, only copied (the requests of the app are made through it, see lib/network/generated_transport.dart).
"""
from __future__ import annotations

import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VENDORED = ROOT / "lib" / "generated" / "hydra_server_client.dart"
SDK_ROOT = Path(os.environ["HYDRA_UMC_SDK_DIR"]) if os.environ.get("HYDRA_UMC_SDK_DIR") else ROOT.parent / "HYDRA-UMC-SDK"
SOURCE = SDK_ROOT / "generated" / "hydra_server_client.dart"


def _text(path: Path) -> bytes:
    return path.read_bytes().replace(b"\r\n", b"\n")


def main(argv: list[str]) -> int:
    if not SOURCE.is_file():
        print("SKIP: the SDK generated client is not available (set HYDRA_UMC_SDK_DIR or put HYDRA-UMC-SDK next to this repository)")
        return 0
    if "--check" in argv:
        if not VENDORED.is_file() or _text(VENDORED) != _text(SOURCE):
            print(f"FAIL: {VENDORED.relative_to(ROOT).as_posix()} differs from the SDK file; run python tools/sync_sdk_client.py", file=sys.stderr)
            return 1
        print("PASS: the vendored server client equals the SDK generated client")
        return 0
    VENDORED.parent.mkdir(parents=True, exist_ok=True)
    VENDORED.write_bytes(_text(SOURCE))
    print("copied the SDK generated server client")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
