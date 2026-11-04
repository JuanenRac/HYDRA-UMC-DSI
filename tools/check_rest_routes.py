#!/usr/bin/env python3
# =============================================================================
# HYDRA-UMC-DSI - tools/check_rest_routes.py
# Copyright (C) 2026 JuanenRac (Electro Hobby 3D)
# GPL-3.0-or-later - see LICENSE
# =============================================================================
"""Fixes the list of server routes this app calls and checks it against the server contract.

    python tools/check_rest_routes.py            # compare the sources with docs/rest_routes.json (and the contract when it is next to this repository)
    python tools/check_rest_routes.py --check    # the same, as the CI validator runs it
    python tools/check_rest_routes.py --record   # write docs/rest_routes.json from the sources (on purpose, after adding or dropping a route)

A route can only be added or dropped on purpose (record it again); when the shared contracts are checked out next to this repository, every route
must exist in the server contract, so an app cannot call a route the server does not have. The relay of the server to the local services
(/api/ai/<service>/...) is one wildcard route that the inventory does not list path by path, so it is not compared.
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RECORDED = ROOT / "docs" / "rest_routes.json"
SOURCE_DIRS = ("app/src/main", "lib")
SOURCE_SUFFIXES = (".kt", ".dart", ".swift")
CONTRACT = ROOT.parent / "HYDRA-UMC-SDK" / "contracts" / "openapi" / "v1" / "server.full.openapi.json"
STRING = re.compile(r'"([^"]*)"' + "|" + r"'([^']*)'")
INSIDE = re.compile(r"(/api/\S*)")


def normalize(raw: str) -> str:
    route = re.sub(r"\$\{[^}]*\}?|\\\([^)]*\)|\$\w+", "{p}", raw).split("?")[0]
    route = re.sub(r"([^/])\{p\}.*$", r"\1", route)  # '/api/audit$query' is '/api/audit'
    return route.rstrip("/")


def called_routes() -> list[str]:
    found: set[str] = set()
    for directory in SOURCE_DIRS:
        base = ROOT / directory
        if not base.is_dir():
            continue
        for path in sorted(base.rglob("*")):
            if path.suffix not in SOURCE_SUFFIXES or not path.is_file():
                continue
            for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
                code = re.sub(r"(^|\s)//.*$", "", line)  # comments hold examples, not calls
                if code.lstrip().startswith(("*", "/*")):
                    continue
                for string in STRING.finditer(code):
                    inside = INSIDE.search(string.group(1) or string.group(2) or "")
                    if inside:
                        route = normalize(inside.group(1))
                        if len(route) > 5:
                            found.add(route)
    return sorted(found)


def contract_problems(routes: list[str]) -> list[str]:
    if not CONTRACT.is_file():
        return []
    paths = list(json.loads(CONTRACT.read_text(encoding="utf-8")).get("paths", {}))

    def matches(route: str, path: str) -> bool:
        return re.fullmatch(re.escape(route).replace(r"\{p\}", "[^/]+"), re.sub(r"\{[^}]+\}", "x", path)) is not None

    return [f"{route} is not in the server contract" for route in routes if not route.startswith("/api/ai/") and not any(matches(route, p) for p in paths)]


def main(argv: list[str]) -> int:
    routes = called_routes()
    if "--record" in argv:
        RECORDED.write_text(json.dumps(routes, indent=2) + "\n", encoding="utf-8")
        print(f"REST_ROUTES=RECORDED {len(routes)} routes")
        return 0
    problems = contract_problems(routes)
    if not RECORDED.is_file():
        problems.append("docs/rest_routes.json is missing (run tools/check_rest_routes.py --record)")
    else:
        recorded = json.loads(RECORDED.read_text(encoding="utf-8"))
        problems += [f"{r} is called but not recorded" for r in routes if r not in recorded]
        problems += [f"{r} is recorded but no longer called" for r in recorded if r not in routes]
    if problems:
        print("REST_ROUTES=FAIL " + "; ".join(problems))
        return 1
    print(f"REST_ROUTES=PASS {len(routes)} routes" + ("" if CONTRACT.is_file() else " (server contract not next to this repository: only the recorded list was compared)"))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
