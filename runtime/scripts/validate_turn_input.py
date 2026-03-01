#!/usr/bin/env python3
"""Validate explicit player-action provenance before runtime mechanics execution."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any, Dict, List

REQUIRED_STR_FIELDS = ("player_action_text", "player_action_source", "player_action_message_id")
REQUIRED_BOOL_FIELDS = ("action_confirmed",)
ALLOWED_SOURCES = {"user_verbatim"}


def _load_json(path: Path) -> Dict[str, Any]:
    return json.loads(path.read_text())


def validate_turn_input(payload: Dict[str, Any]) -> List[str]:
    errors: List[str] = []

    for field in REQUIRED_STR_FIELDS:
        value = payload.get(field)
        if not isinstance(value, str) or not value.strip():
            errors.append(f"{field}: required non-empty string")

    source = payload.get("player_action_source")
    if isinstance(source, str) and source not in ALLOWED_SOURCES:
        allowed = ", ".join(sorted(ALLOWED_SOURCES))
        errors.append(f"player_action_source: must be one of [{allowed}]")

    for field in REQUIRED_BOOL_FIELDS:
        value = payload.get(field)
        if not isinstance(value, bool):
            errors.append(f"{field}: required boolean")
    if payload.get("action_confirmed") is not True:
        errors.append("action_confirmed: must be true")

    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate runtime turn input provenance payload")
    parser.add_argument("--input-json", required=True, help="Path to JSON payload containing player action provenance")
    args = parser.parse_args()

    path = Path(args.input_json)
    try:
        payload = _load_json(path)
    except FileNotFoundError:
        print(json.dumps({"valid": False, "errors": [f"input-json not found: {path}"]}))
        return 2
    except json.JSONDecodeError as exc:
        print(json.dumps({"valid": False, "errors": [f"invalid JSON: {exc}"]}))
        return 2

    errors = validate_turn_input(payload)
    if errors:
        print(json.dumps({"valid": False, "errors": errors}, indent=2))
        return 1

    print(json.dumps({"valid": True, "errors": []}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
