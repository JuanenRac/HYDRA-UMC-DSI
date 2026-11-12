#!/usr/bin/env python3
# =============================================================================
# HYDRA-UMC-SDK - conformance/fake-server/hydra_fake_server.py
# Copyright (C) 2026 JuanenRac (Electro Hobby 3D) <electrohobby3d@gmail.com>
# GPL-3.0-or-later - see LICENSE
# =============================================================================
"""One stand-in for HYDRA-UMC-SERVER that every app and client can be tested against.

It keeps state, so a test can tell a story and not only replay one answer:

  * sign-in, refresh (the refresh token turns over: the old one stops working) and sign-out;
  * robots with a revision that moves with every accepted write, `If-Match` answered with 412 when it is old;
  * reservations (`claim`, `release`) that belong to the account AND the controller, with the stable refusal codes
    (`other-account`, `other-controller`, `controller-id-required`);
  * the jog that has to be armed first (`jog-not-armed`), the robot in safe mode (423 `robot-disabled`), the global STOP
    that stops every robot and says so robot by robot;
  * the feeds the sibling services hand to the server: `GET /api/faults` (the faults a test raises with `raise_fault`),
    `POST /api/ingest/scenario-outcome` (a ScenarioOutcome 1.0 is kept, one that does not fit is a 400),
    `POST /api/ingest/developer-node/status` (the token of a node, `node_tokens`, and not a user account) and
    `POST /api/trajectory/proposals/verify` (a listed key and the signature `fake-valid`: no cryptography here);
  * `POST /api/camera/ticket`: a ticket for a picture's address (`{ticket, expiresInSeconds}`), valid for five minutes of the test
    clock and kept in `tickets` (ticket -> account and expiry) for a test to look at; `ticket_valid` says if one still opens a picture;
  * every other route of the full server inventory answers with the `full` body of
    `conformance/app-fixtures/v1/server-answers.json` (the same file the apps replay), so a client can call any route the
    server declares; a route the inventory does not know is a 404.

Standard library only. Run it with `python hydra_fake_server.py --port 3000` (user `admin`, password `admin`; change them with
`--user` / `--password`; `--port 0` takes a free port and says which; `HYDRA_FAKE_ANSWERS` names another copy of the answers file); nothing here ever moves hardware and nothing reads a secret.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import secrets
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any
from urllib.parse import urlparse

ANSWERS = Path(__file__).resolve().parent.parent / "app-fixtures" / "v1" / "server-answers.json"
OPEN_ROUTES = {("GET", "/api/hydra-info"), ("POST", "/api/login"), ("POST", "/api/refresh"), ("POST", "/api/logout"), ("GET", "/.well-known/jwks.json")}
CONTINUOUS = {"jog", "speed", "jogStep"}
CLAIM_TTL_MS = 300_000
TICKET_TTL_S = 300


class FakeHydra:
    """The state of one pretend server. Every method is called with the lock held."""

    def __init__(self, user: str = "admin", password: str = "admin", robots: int = 2) -> None:
        self.lock = threading.RLock()
        self.user = user
        self.password = password
        self.now_ms = 1_000_000  # a clock the test moves, so no real time leaks into the answers
        self.tokens: dict[str, str] = {}
        self.refresh_tokens: set[str] = set()
        self.robots: dict[int, dict[str, Any]] = {
            i: {"id": i, "name": f"Robot {i}", "online": True, "enabled": True, "stopped": False, "revision": "r1", "counter": 1, "claim": None, "armed_until": 0}
            for i in range(1, robots + 1)
        }
        self.requests: list[tuple[str, str]] = []  # (method, path) of every request, for a test to look at
        self.faults: list[dict[str, Any]] = []  # the active faults of GET /api/faults
        self.scenario_outcomes: list[dict[str, Any]] = []
        self.node_tokens: dict[str, str] = {}  # token -> node id, for the developer node
        self.node_statuses: dict[str, dict[str, Any]] = {}
        self.proposal_keys: set[str] = set()  # the key ids the verify route knows
        self.verified: list[dict[str, Any]] = []  # the bodies of the verify calls
        self.tickets: dict[str, tuple[str, int]] = {}  # camera ticket -> (account, expiry on the test clock)

    # ---- helpers ------------------------------------------------------------------------------------
    def bump(self, robot: dict[str, Any]) -> str:
        robot["counter"] += 1
        robot["revision"] = f"r{robot['counter']}"
        return robot["revision"]

    def claim_of(self, robot: dict[str, Any]) -> dict[str, Any] | None:
        claim = robot["claim"]
        if claim and claim["expiresAt"] <= self.now_ms:
            robot["claim"] = None
        return robot["claim"]

    def view(self, robot: dict[str, Any]) -> dict[str, Any]:
        claim = self.claim_of(robot)
        return {
            "id": robot["id"], "name": robot["name"], "online": robot["online"], "enabled": robot["enabled"], "stopped": robot["stopped"],
            "revision": robot["revision"], "reservation": claim, "jogArmedUntil": robot["armed_until"] if robot["armed_until"] > self.now_ms else None,
        }

    def refusal(self, status: int, error: str, code: str | None = None, robot: dict[str, Any] | None = None) -> tuple[int, dict[str, Any]]:
        body: dict[str, Any] = {"error": error}
        if code:
            body["code"] = code
        if robot is not None:
            body["revision"] = robot["revision"]
        return status, body

    def conflict(self, robot: dict[str, Any], user: str, controller: str | None) -> tuple[int, dict[str, Any]] | None:
        """The refusal a reservation gives to this caller, or None when the caller may go on."""
        claim = self.claim_of(robot)
        if claim is None:
            return None
        if claim["ownerUsername"] != user:
            return self.refusal(409, "Robot is reserved by another account", "other-account", robot)
        if claim["controllerId"] and controller is None:
            return self.refusal(409, "The reservation names a controller", "controller-id-required", robot)
        if claim["controllerId"] and controller != claim["controllerId"]:
            return self.refusal(409, "Robot is reserved by this account from another controller", "other-controller", robot)
        return None

    # ---- routes -------------------------------------------------------------------------------------
    def login(self, body: dict[str, Any]) -> tuple[int, dict[str, Any]]:
        if body.get("username") != self.user or body.get("password") != self.password:
            return 401, {"error": "Invalid credentials"}
        token, refresh = "tok-" + secrets.token_hex(8), "ref-" + secrets.token_hex(8)
        self.tokens[token] = self.user
        self.refresh_tokens.add(refresh)
        return 200, {"success": True, "token": token, "refreshToken": refresh, "role": "admin"}

    def refresh(self, body: dict[str, Any]) -> tuple[int, dict[str, Any]]:
        old = body.get("refreshToken")
        if old not in self.refresh_tokens:
            return 401, {"error": "Invalid refresh token"}
        self.refresh_tokens.discard(old)  # it turns over: the old one is dead
        token, refresh = "tok-" + secrets.token_hex(8), "ref-" + secrets.token_hex(8)
        self.tokens[token] = self.user
        self.refresh_tokens.add(refresh)
        return 200, {"success": True, "token": token, "refreshToken": refresh, "role": "admin"}

    def logout(self, body: dict[str, Any]) -> tuple[int, dict[str, Any]]:
        self.refresh_tokens.discard(body.get("refreshToken"))
        return 200, {"success": True}

    def robot_or_404(self, robot_id: int) -> dict[str, Any] | None:
        return self.robots.get(robot_id)

    def if_match_refusal(self, robot: dict[str, Any], if_match: str | None) -> tuple[int, dict[str, Any]] | None:
        if if_match is not None and if_match.strip('"') != robot["revision"]:
            return self.refusal(412, "The robot changed since it was read", "revision-mismatch", robot)
        return None

    def claim(self, robot_id: int, user: str, body: dict[str, Any], if_match: str | None) -> tuple[int, dict[str, Any]]:
        robot = self.robot_or_404(robot_id)
        if robot is None:
            return 404, {"error": "Robot not found"}
        controller = body.get("controllerId") or None
        stale = self.if_match_refusal(robot, if_match)
        if stale:
            return stale
        blocked = self.conflict(robot, user, controller)
        if blocked:
            return blocked
        robot["claim"] = {"robotId": robot_id, "robotName": robot["name"], "ownerUsername": user, "controllerId": controller, "expiresAt": self.now_ms + CLAIM_TTL_MS}
        return 200, {"success": True, "reservation": robot["claim"], "reservationHistory": [], "revision": self.bump(robot)}

    def release(self, robot_id: int, user: str, body: dict[str, Any], if_match: str | None) -> tuple[int, dict[str, Any]]:
        robot = self.robot_or_404(robot_id)
        if robot is None:
            return 404, {"error": "Robot not found"}
        stale = self.if_match_refusal(robot, if_match)
        if stale:
            return stale
        blocked = self.conflict(robot, user, body.get("controllerId") or None)
        if blocked:
            return blocked
        robot["claim"] = None
        robot["armed_until"] = 0
        return 200, {"success": True, "reservationHistory": [], "revision": self.bump(robot)}

    def jog_arm(self, robot_id: int, user: str, body: dict[str, Any]) -> tuple[int, dict[str, Any]]:
        robot = self.robot_or_404(robot_id)
        if robot is None:
            return 404, {"error": "Robot not found"}
        if not robot["enabled"]:
            return self.refusal(423, "Robot is in safe mode", "robot-disabled", robot)
        blocked = self.conflict(robot, user, body.get("controllerId") or None)
        if blocked:
            return blocked
        armed = bool(body.get("armed", True))
        robot["armed_until"] = self.now_ms + 60_000 if armed else 0
        return 200, {"success": True, "jogArmedUntil": robot["armed_until"] or None, "revision": self.bump(robot)}

    def command(self, robot_id: int, user: str, body: dict[str, Any], if_match: str | None) -> tuple[int, dict[str, Any]]:
        robot = self.robot_or_404(robot_id)
        if robot is None:
            return 404, {"error": "Robot not found"}
        command = body.get("command")
        if not isinstance(command, str) or not command:
            return 400, {"error": "A command is needed"}
        if command == "stop":  # STOP is never refused for a reservation, a revision or safe mode
            robot["stopped"] = True
            return 200, {"success": True, "revision": self.bump(robot)}
        if not robot["enabled"]:
            return self.refusal(423, "Robot is in safe mode", "robot-disabled", robot)
        blocked = self.conflict(robot, user, body.get("controllerId") or None)
        if blocked:
            return blocked
        if command not in CONTINUOUS:
            stale = self.if_match_refusal(robot, if_match)
            if stale:
                return stale
        if command == "jog" and robot["armed_until"] <= self.now_ms:
            return self.refusal(403, "The jog has to be armed first", "jog-not-armed", robot)
        if command == "disable":
            robot["enabled"] = False
        elif command == "enable":
            robot["enabled"] = True
        else:
            robot["stopped"] = False
        return 200, {"success": True, "revision": self.bump(robot)}

    def stop_all(self) -> tuple[int, dict[str, Any]]:
        results = []
        for robot in self.robots.values():
            robot["stopped"] = True
            self.bump(robot)
            results.append({"robotId": robot["id"], "controllerId": "fake", "name": robot["name"], "stopped": True, "valvesOff": 0, "pumpsOff": 0})
        return 200, {"success": True, "stoppedCount": len(results), "failedCount": 0, "persisted": True, "robots": results}

    def claims(self) -> tuple[int, dict[str, Any]]:
        return 200, {"claims": [c for r in self.robots.values() if (c := self.claim_of(r))]}

    def settings(self) -> tuple[int, dict[str, Any]]:
        return 200, {"controllers": [{"id": "fake", "name": "Fake controller", "robots": [self.view(r) for r in self.robots.values()]}]}


    # ---- the feeds ----------------------------------------------------------------------------------
    def raise_fault(self, source: str, code: str, severity: str = "error", text: str = "", robot_id: str | None = None) -> None:
        """A `fault-event/1` raised, the way the server keeps it (camelCase `robotId`, `since` in milliseconds)."""
        self.faults.append({"schema": "fault-event/1", "source": source, "robotId": robot_id, "code": code, "severity": severity, "text": text, "state": "raised", "since": self.now_ms})

    def faults_answer(self, active_only: bool) -> tuple[int, dict[str, Any]]:
        body: dict[str, Any] = {"active": list(self.faults)}
        if not active_only:
            body["recent"] = list(self.faults)
        return 200, body

    def ingest_scenario(self, body: dict[str, Any]) -> tuple[int, dict[str, Any]]:
        if body.get("schema_version") != "1.0" or not isinstance(body.get("scenario_id"), str) or not body.get("scenario_id"):
            return 400, {"error": "not a ScenarioOutcome 1.0"}
        self.scenario_outcomes.append(body)
        return 201, {"seq": len(self.scenario_outcomes), "hash": f"{len(self.scenario_outcomes):064x}"}

    def ingest_node_status(self, token: str, body: dict[str, Any]) -> tuple[int, dict[str, Any]]:
        node = self.node_tokens.get(token)
        if node is None:
            return 401, {"error": "a valid node token is required"}
        if body.get("schema") != "developer-node-status/1":
            return 400, {"error": "not a developer-node-status/1"}
        self.node_statuses[node] = body
        return 201, {"node_id": node, "seq": len(self.node_statuses)}

    def camera_ticket(self, user: str) -> tuple[int, dict[str, Any]]:
        """The short-lived ticket a picture's address carries: the answer of the real route, `{ticket, expiresInSeconds}`."""
        ticket = "tkt-" + secrets.token_hex(12)
        self.tickets[ticket] = (user, self.now_ms + TICKET_TTL_S * 1000)
        return 200, {"ticket": ticket, "expiresInSeconds": TICKET_TTL_S}

    def ticket_valid(self, ticket: str) -> bool:
        entry = self.tickets.get(ticket)
        return entry is not None and entry[1] > self.now_ms

    def verify_proposal(self, body: dict[str, Any]) -> tuple[int, dict[str, Any]]:
        proposal = body.get("proposal")
        if not isinstance(proposal, dict) or not isinstance(body.get("expected_robot_id"), str):
            return 400, {"error": "proposal and expected_robot_id are required"}
        if not self.proposal_keys:
            return 503, {"error": "no proposal key is listed"}
        self.verified.append(body)
        key_id = str(proposal.get("key_id", ""))
        reason = "ok"
        if key_id not in self.proposal_keys:
            reason = "unknown-key"
        elif proposal.get("signature") != "fake-valid":
            reason = "bad-signature"
        elif str(proposal.get("robot_id")) != body["expected_robot_id"]:
            reason = "wrong-robot"
        return 200, {"valid": reason == "ok", "reason": reason, "key_id": key_id}


def load_answers() -> dict[str, Any]:
    # An app that carries a copy of the answers next to its tests points here instead of at the SDK tree.
    source = Path(os.environ["HYDRA_FAKE_ANSWERS"]) if os.environ.get("HYDRA_FAKE_ANSWERS") else ANSWERS
    return json.loads(source.read_text(encoding="utf-8"))["routes"]


def _template_regex(path: str) -> re.Pattern[str]:
    return re.compile("^" + re.sub(r"\\\{.+?\\\}", "[^/]+", re.escape(path)) + "$")


class Handler(BaseHTTPRequestHandler):
    server: "FakeServer"
    protocol_version = "HTTP/1.1"

    def log_message(self, format: str, *args: object) -> None:  # noqa: A002 - quiet
        pass

    def _send(self, status: int, body: Any) -> None:
        data = json.dumps(body).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        if isinstance(body, dict) and isinstance(body.get("revision"), str):
            self.send_header("ETag", f'"{body["revision"]}"')
        self.end_headers()
        self.wfile.write(data)

    def _body(self) -> dict[str, Any]:
        length = int(self.headers.get("Content-Length") or 0)
        if not length:
            return {}
        try:
            value = json.loads(self.rfile.read(length) or b"{}")
        except ValueError:
            return {}
        return value if isinstance(value, dict) else {}

    def _handle(self, method: str) -> None:
        parsed = urlparse(self.path)
        path = parsed.path
        state = self.server.state
        body = self._body() if method in ("POST", "PUT", "PATCH") else {}
        with state.lock:
            state.requests.append((method, path))
            if (method, path) == ("POST", "/api/ingest/developer-node/status"):
                header = self.headers.get("Authorization", "")
                status, answer = state.ingest_node_status(header[7:] if header.startswith("Bearer ") else "", body)
                return self._send(status, answer)
            user = None
            if (method, path) not in OPEN_ROUTES:
                header = self.headers.get("Authorization", "")
                user = state.tokens.get(header[7:]) if header.startswith("Bearer ") else None
                if user is None:
                    return self._send(401, {"error": "Access denied", "code": "TOKEN_INVALID"})
            status, answer = self._route(method, path, body, user or "")
        self._send(status, answer)

    def _route(self, method: str, path: str, body: dict[str, Any], user: str) -> tuple[int, Any]:
        state = self.server.state
        if_match = self.headers.get("If-Match")
        if (method, path) == ("POST", "/api/login"):
            return state.login(body)
        if (method, path) == ("POST", "/api/refresh"):
            return state.refresh(body)
        if (method, path) == ("POST", "/api/logout"):
            return state.logout(body)
        if (method, path) == ("POST", "/api/stop-all"):
            return state.stop_all()
        if (method, path) == ("GET", "/api/claims"):
            return state.claims()
        if (method, path) == ("GET", "/api/settings"):
            return state.settings()
        if (method, path) == ("GET", "/api/faults"):
            return state.faults_answer("active=1" in (urlparse(self.path).query or "").split("&"))
        if (method, path) == ("POST", "/api/ingest/scenario-outcome"):
            return state.ingest_scenario(body)
        if (method, path) == ("POST", "/api/trajectory/proposals/verify"):
            return state.verify_proposal(body)
        if (method, path) == ("POST", "/api/camera/ticket"):
            return state.camera_ticket(user)
        found = re.fullmatch(r"/api/robot/(\d+)(?:/(claim|release|jog-arm|command))?", path)
        if found:
            robot_id, action = int(found.group(1)), found.group(2)
            if action is None and method == "GET":
                robot = state.robot_or_404(robot_id)
                return (200, {"robot": state.view(robot), "revision": robot["revision"]}) if robot else (404, {"error": "Robot not found"})
            if method == "POST" and action == "claim":
                return state.claim(robot_id, user, body, if_match)
            if method == "POST" and action == "release":
                return state.release(robot_id, user, body, if_match)
            if method == "POST" and action == "jog-arm":
                return state.jog_arm(robot_id, user, body)
            if method == "POST" and action == "command":
                return state.command(robot_id, user, body, if_match)
        return self._from_inventory(method, path)

    def _from_inventory(self, method: str, path: str) -> tuple[int, Any]:
        for template, by_status in self.server.answers.items():
            verb, route = template.split(" ", 1)
            if verb == method and _template_regex(route).match(path):
                ok = by_status.get("200") or next(iter(by_status.values()), None)
                status = 200 if "200" in by_status else int(next(iter(by_status), "404"))
                if ok is not None:
                    return status, ok["full"]
        return 404, {"error": "Not a route of the server inventory"}

    def do_GET(self) -> None:  # noqa: N802
        self._handle("GET")

    def do_POST(self) -> None:  # noqa: N802
        self._handle("POST")

    def do_PUT(self) -> None:  # noqa: N802
        self._handle("PUT")

    def do_PATCH(self) -> None:  # noqa: N802
        self._handle("PATCH")

    def do_DELETE(self) -> None:  # noqa: N802
        self._handle("DELETE")


class FakeServer(ThreadingHTTPServer):
    daemon_threads = True

    def __init__(self, address: tuple[str, int], state: FakeHydra) -> None:
        super().__init__(address, Handler)
        self.state = state
        self.answers = load_answers()


def start(state: FakeHydra | None = None, port: int = 0, host: str = "127.0.0.1") -> tuple[FakeServer, threading.Thread]:
    """Starts the server on a thread (port 0 = any free port); `server.server_address[1]` is the port."""
    server = FakeServer((host, port), state or FakeHydra())
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    return server, thread


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--port", type=int, default=3000)
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--user", default="admin")
    parser.add_argument("--password", default="admin")
    parser.add_argument("--robots", type=int, default=2)
    args = parser.parse_args()
    server, thread = start(FakeHydra(args.user, args.password, args.robots), args.port, args.host)
    print(f"fake HYDRA-UMC server on http://{args.host}:{server.server_address[1]} (user {args.user})", flush=True)  # flushed: a test that starts this as a process reads the port from this line
    try:
        thread.join()
    except KeyboardInterrupt:
        server.shutdown()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
