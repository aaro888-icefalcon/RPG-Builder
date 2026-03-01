#!/usr/bin/env python3
"""Validate canonical reference paths in phase skill and governance files.

Scans all .md files under runtime/phases/ for backtick-wrapped file paths
and verifies the referenced files exist. Catches stale paths left behind
by directory restructures.

Resolution order for each path:
  1. Relative to the source file's parent directory
  2. Repo-root-relative (for runtime/, development/, archives/ prefixes)
  3. Runtime-relative (for phases/, scripts/, schemas/, tests/ prefixes)

A path is only reported as broken if it matches a known prefix pattern
(step 2 or 3) AND cannot be resolved by any method.
"""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]  # runtime/
REPO_ROOT = ROOT.parent

# Prefix groups for absolute path resolution.
REPO_ROOT_PREFIXES = ("runtime/", "development/", "archives/")
RUNTIME_PREFIXES = ("phases/", "scripts/", "schemas/", "tests/")

# Match backtick-wrapped file paths containing at least one /
# and ending with a known extension. Optional §section suffix is stripped.
BACKTICK_PATH = re.compile(
    r"`("
    r"[A-Za-z][A-Za-z0-9_\-.]*"  # first segment
    r"/[A-Za-z0-9_\-./]+"        # at least one / plus more segments
    r"\.(?:md|py|json|sh|yaml|yml)"  # file extension
    r")"
    r"(?:\s+§[^`]*)?"  # optional section reference
    r"`"
)


def check_path(raw: str, source_file: Path) -> bool | None:
    """Check whether a path reference is valid.

    Returns:
      True  -- path resolves to an existing file
      False -- path matches a known prefix but the file is missing (broken)
      None  -- path does not match any known pattern (skip)
    """
    # 1. Try relative to the source file's directory.
    if (source_file.parent / raw).exists():
        return True

    # 2. Try repo-root-relative.
    for prefix in REPO_ROOT_PREFIXES:
        if raw.startswith(prefix):
            return (REPO_ROOT / raw).exists()

    # 3. Try runtime-relative.
    for prefix in RUNTIME_PREFIXES:
        if raw.startswith(prefix):
            return (ROOT / raw).exists()

    # Not a recognized pattern -- skip silently.
    return None


def scan_file(md_path: Path) -> list[tuple[int, str]]:
    """Return (line_number, raw_path) pairs for broken references in a file."""
    broken: list[tuple[int, str]] = []
    text = md_path.read_text(encoding="utf-8")
    for lineno, line in enumerate(text.splitlines(), start=1):
        for match in BACKTICK_PATH.finditer(line):
            raw = match.group(1)
            result = check_path(raw, md_path)
            if result is False:
                broken.append((lineno, raw))
    return broken


def main() -> int:
    errors: list[str] = []

    phases_dir = ROOT / "phases"
    if not phases_dir.exists():
        print("Canonical reference validation FAILED: runtime/phases/ not found")
        return 1

    md_files = sorted(phases_dir.rglob("*.md"))
    broken_count = 0

    for md_file in md_files:
        rel = md_file.relative_to(REPO_ROOT)
        for lineno, raw_path in scan_file(md_file):
            errors.append(f"{rel}:{lineno}: broken path `{raw_path}`")
            broken_count += 1

    if errors:
        print(f"Canonical reference validation FAILED ({broken_count} broken path(s)):")
        for e in errors:
            print(f"  - {e}")
        return 1

    print(f"Canonical reference validation PASSED ({len(md_files)} files scanned)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
