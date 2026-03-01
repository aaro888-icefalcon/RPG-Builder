#!/usr/bin/env python3
"""Validate docs structure contracts for phase-oriented architecture.

Checks:
- required hub/index files exist (runtime-relative and repo-root-relative)
- phase CLAUDE.md and index.md files exist for all 6 pipeline phases
- domain index files exist for Phase 3 skill sub-groups
- archived outlier pointer exists after relocation
- schema-doc sync: schema files exist, migration notes reference current version,
  reference-freshness.md tracks schema docs
"""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = ROOT.parent

# Files that must exist under runtime/
REQUIRED_RUNTIME_FILES = [
    "CLAUDE.md",
    "index.md",
    "turn-loop.md",
    "play-runbook.md",
    "scripts/CLAUDE.md",
    "scripts/index.md",
    "tests/index.md",
    "phases/CLAUDE.md",
    "phases/index.md",
    "phases/phase-manifest.md",
    # Phase 1
    "phases/1-context-loading/CLAUDE.md",
    "phases/1-context-loading/index.md",
    # Phase 2
    "phases/2-action-interpretation/CLAUDE.md",
    "phases/2-action-interpretation/index.md",
    # Phase 3
    "phases/3-resolution/CLAUDE.md",
    "phases/3-resolution/index.md",
    # Phase 3 domains (populated per-game; no required defaults)
    # Phase 4
    "phases/4-narrative/CLAUDE.md",
    "phases/4-narrative/index.md",
    # Phase 5
    "phases/5-persistence/CLAUDE.md",
    "phases/5-persistence/index.md",
    # Phase 6
    "phases/6-validation/CLAUDE.md",
    "phases/6-validation/index.md",
]

# Files that must exist under repo root
REQUIRED_DEV_FILES = [
    "development/index.md",
    "development/repo-maintenance-policy.md",
    "development/appendices/index.md",
]

# Schema-related files that must exist under runtime/
REQUIRED_SCHEMA_FILES = [
    "schemas/state.schema.json",
    "scripts/validate_state.py",
    "tests/test_state_schema.py",
]

# Schema-related dev files that must exist under repo root
REQUIRED_SCHEMA_DEV_FILES = [
    "development/quality/state-schema-migration-notes.md",
]

OUTLIER_POINTER_CHECKS = {
    # Add game-specific outlier pointer checks as needed
}


def validate_files(errors: list[str]) -> None:
    for rel_path in REQUIRED_RUNTIME_FILES:
        file_path = ROOT / rel_path
        if not file_path.exists():
            errors.append(f"missing required file: runtime/{rel_path}")

    for rel_path in REQUIRED_DEV_FILES:
        file_path = REPO_ROOT / rel_path
        if not file_path.exists():
            errors.append(f"missing required file: {rel_path}")


def validate_schema_docs(errors: list[str]) -> None:
    """Validate schema files exist and docs reference the current schema version."""
    for rel_path in REQUIRED_SCHEMA_FILES:
        file_path = ROOT / rel_path
        if not file_path.exists():
            errors.append(f"missing required schema file: runtime/{rel_path}")

    for rel_path in REQUIRED_SCHEMA_DEV_FILES:
        file_path = REPO_ROOT / rel_path
        if not file_path.exists():
            errors.append(f"missing required schema doc: {rel_path}")

    # Check that migration notes reference the current schema major version
    schema_path = ROOT / "schemas" / "state.schema.json"
    migration_path = REPO_ROOT / "development" / "quality" / "state-schema-migration-notes.md"
    if schema_path.exists() and migration_path.exists():
        schema_data = json.loads(schema_path.read_text(encoding="utf-8"))
        schema_id = schema_data.get("$id", "")
        # Extract major version from $id like "emergence-state-v5" -> "5"
        version_tag = schema_id.rsplit("-", 1)[-1] if "-" in schema_id else ""
        major_version = version_tag.lstrip("v") if version_tag else ""
        migration_text = migration_path.read_text(encoding="utf-8")
        if major_version and major_version not in migration_text:
            errors.append(
                f"state-schema-migration-notes.md does not reference "
                f"schema major version '{major_version}' (from $id: {schema_id})"
            )

    # Check that reference-freshness.md tracks schema docs
    freshness_path = REPO_ROOT / "development" / "quality" / "reference-freshness.md"
    if freshness_path.exists():
        freshness_text = freshness_path.read_text(encoding="utf-8")
        if "state.schema.json" not in freshness_text:
            errors.append(
                "reference-freshness.md does not track schemas/state.schema.json"
            )
        if "validate_state.py" not in freshness_text:
            errors.append(
                "reference-freshness.md does not track scripts/validate_state.py"
            )


def validate_outlier_pointers(errors: list[str]) -> None:
    for rel_path, snippets in OUTLIER_POINTER_CHECKS.items():
        file_path = REPO_ROOT / rel_path
        if not file_path.exists():
            errors.append(f"missing required outlier pointer file: {rel_path}")
            continue
        text = file_path.read_text(encoding="utf-8")
        for snippet in snippets:
            if snippet not in text:
                errors.append(f"{rel_path}: missing pointer snippet '{snippet}'")


def main() -> int:
    errors: list[str] = []

    validate_files(errors)
    validate_schema_docs(errors)
    validate_outlier_pointers(errors)

    if errors:
        print("Docs structure validation FAILED:")
        for error in errors:
            print(f"- {error}")
        return 1

    print("Docs structure validation PASSED")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
