# Scripts — Entry Points

Scope: `runtime/scripts/`

## Purpose

Entry point scripts for CLI execution and validation. Domain modules (the actual game logic) live in `phases/3-resolution/skills/<domain>/scripts/`.

## Operating Rules

- Run scripts from repo root (e.g., `python runtime/scripts/emergence_cli.py ...`).
- Treat script output as operational evidence — do not invent outcomes.
- If a script mutates campaign state, re-check `state.json` after it runs.

## Entry Points

| Script | Purpose | Runtime-safe |
|---|---|---|
| `emergence_cli.py` | Unified CLI dispatcher — no commands registered yet | Yes |
| `validate_state.py` | State JSON schema validation | Yes |
| `validate_turn_input.py` | Player action provenance validation | Yes |
| `validate_turn_receipt.py` | Turn receipt schema validation | Yes |
| `validate_reference_freshness.py` | Reference path freshness check | Development only |
| `validate_docs_structure.py` | Documentation structure + schema-doc sync check | Development only |
| `validate_canonical_references.py` | Canonical reference path validator | Development only |

## Domain Module Locations

Domain scripts are physically co-located with their skills in Phase 3:
- `phases/3-resolution/skills/<domain>/scripts/` — game logic modules
- `phases/3-resolution/skills/<domain>/tables/` — data tables

emergence_cli.py's sys.path includes all domain directories automatically.
