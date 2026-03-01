#!/usr/bin/env python3
"""Validate development/quality/reference-freshness.md table formatting and commit hash syntax."""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REFERENCE_FRESHNESS = ROOT.parent / "development" / "quality" / "reference-freshness.md"
ROW_RE = re.compile(r"^\|\s*`([^`]+)`\s*\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|\s*`([0-9a-f]{40})`\s*\|\s*([^|]+?)\s*\|$")


def main() -> int:
    if not REFERENCE_FRESHNESS.exists():
        print(f"ERROR: Missing file: {REFERENCE_FRESHNESS}")
        return 2

    errors: list[str] = []
    lines = REFERENCE_FRESHNESS.read_text(encoding="utf-8").splitlines()

    for line_no, line in enumerate(lines, start=1):
        if not line.startswith("| `"):
            continue

        match = ROW_RE.match(line)
        if not match:
            errors.append(f"Line {line_no}: malformed table row: {line}")
            continue

        doc_path = match.group(1)
        if not (ROOT / doc_path).exists():
            errors.append(f"Line {line_no}: referenced doc does not exist: {doc_path}")

    if errors:
        print("Reference freshness validation FAILED:")
        for err in errors:
            print(f"- {err}")
        return 1

    print("Reference freshness validation PASSED")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
