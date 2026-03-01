#!/usr/bin/env python3
"""Validate runtime turn receipt contract with schema-version-aware enforcement."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any, Dict, List

STRICT_REQUIRED_FIELDS = (
    "receipt_schema_version",
    "turn_id",
    "player_action_text",
    "player_action_source",
    "player_action_message_id",
    "action_confirmed",
    "commands_executed",
    "checks_run",
    "files_touched",
)


def _load_json(path: Path) -> Dict[str, Any]:
    return json.loads(path.read_text())


def _validate_v2(receipt: Dict[str, Any]) -> List[str]:
    errors: List[str] = []

    for field in STRICT_REQUIRED_FIELDS:
        if field not in receipt:
            errors.append(f"{field}: missing required field")

    if isinstance(receipt.get("turn_id"), str) is False or not receipt.get("turn_id", "").strip():
        errors.append("turn_id: required non-empty string")

    source = receipt.get("player_action_source")
    if source != "user_verbatim":
        errors.append("player_action_source: must equal 'user_verbatim'")

    if receipt.get("action_confirmed") is not True:
        errors.append("action_confirmed: must be true")

    for list_field in ("commands_executed", "checks_run", "files_touched"):
        value = receipt.get(list_field)
        if not isinstance(value, list) or not value:
            errors.append(f"{list_field}: required non-empty array")

    if "seed" in receipt and not isinstance(receipt.get("seed"), int):
        errors.append("seed: must be int when present")

    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate turn receipt JSON contract")
    parser.add_argument("--receipt-json", required=True, help="Path to turn receipt JSON")
    args = parser.parse_args()

    path = Path(args.receipt_json)
    try:
        receipt = _load_json(path)
    except FileNotFoundError:
        print(json.dumps({"valid": False, "errors": [f"receipt-json not found: {path}"]}))
        return 2
    except json.JSONDecodeError as exc:
        print(json.dumps({"valid": False, "errors": [f"invalid JSON: {exc}"]}))
        return 2

    version = int(receipt.get("receipt_schema_version", 1))
    if version >= 2:
        errors = _validate_v2(receipt)
        if errors:
            print(json.dumps({"valid": False, "schema_version": version, "errors": errors}, indent=2))
            return 1
        print(json.dumps({"valid": True, "schema_version": version, "errors": []}, indent=2))
        return 0

    print(
        json.dumps(
            {
                "valid": True,
                "schema_version": version,
                "warnings": ["legacy receipt schema: strict provenance checks not enforced"],
                "errors": [],
            },
            indent=2,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
