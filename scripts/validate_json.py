#!/usr/bin/env python3
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def load(name: str) -> dict:
    path = ROOT / name
    with path.open("r", encoding="utf-8") as fh:
        return json.load(fh)


def require_abs(value: str, label: str) -> None:
    if not isinstance(value, str) or not value.startswith("/"):
        raise AssertionError(f"{label} must be an absolute path: {value!r}")


def validate_projects() -> None:
    doc = load("workspace.projects.json")
    assert doc["version"] == "workspace.projects.v1"
    require_abs(doc["srcRoot"], "srcRoot")
    require_abs(doc["contractRoot"], "contractRoot")

    seen = set()
    for project in doc["projects"]:
        pid = project["id"]
        if pid in seen:
            raise AssertionError(f"duplicate project id: {pid}")
        seen.add(pid)

        require_abs(project["root"], f"projects[{pid}].root")
        assert project["env"]["TERM_PROJECT_ID"] == pid
        assert project["env"]["TERM_PROJECT_ROOT"] == project["root"]
        assert project["adapters"]["wezterm"]["cwd"] == project["root"]
        assert project["adapters"]["just"]["cwd"] == project["root"]
        assert project["adapters"]["xplr"]["cwd"] == project["root"]


def validate_hosts() -> None:
    doc = load("workspace.hosts.json")
    assert doc["version"] == "workspace.hosts.v1"
    seen = set()
    for host in doc["hosts"]:
        hid = host["id"]
        if hid in seen:
            raise AssertionError(f"duplicate host id: {hid}")
        seen.add(hid)
        require_abs(host["root"], f"hosts[{hid}].root")
        for surface, payload in host["surfaces"].items():
            for key, value in payload.items():
                require_abs(value, f"hosts[{hid}].surfaces.{surface}.{key}")


def validate_domains() -> None:
    doc = load("workspace.domains.json")
    assert doc["version"] == "workspace.domains.v1"
    seen = set()
    for domain in doc["domains"]:
        name = domain["name"]
        if name in seen:
            raise AssertionError(f"duplicate domain name: {name}")
        seen.add(name)
        require_abs(domain["root"], f"domains[{name}].root")


def main() -> int:
    validate_projects()
    validate_hosts()
    validate_domains()
    print("workspace contract JSON projections validated")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
