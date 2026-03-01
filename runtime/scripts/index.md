# Scripts — Content Inventory

## Purpose
Entry point scripts for CLI execution and validation. Domain modules (game logic) live in `phases/3-resolution/skills/<domain>/scripts/`.

## What belongs here
- Runtime-safe command entrypoints (`emergence_cli.py`, validators).
- Development-only validators (`validate_reference_freshness.py`, `validate_docs_structure.py`, `validate_canonical_references.py`).

## What does not belong here
- Domain logic modules (put in `phases/3-resolution/skills/<domain>/scripts/`).
- Canonical rules prose (put in owning phase's `references/` directory).

## Entry Points

| Script | Purpose | Runtime-safe |
|---|---|---|
| `emergence_cli.py` | Unified CLI dispatcher | Yes |
| `validate_state.py` | State JSON schema validation | Yes |
| `validate_turn_input.py` | Player action provenance validation | Yes |
| `validate_turn_receipt.py` | Turn receipt schema validation | Yes |
| `validate_reference_freshness.py` | Reference path freshness check | Development only |
| `validate_docs_structure.py` | Documentation structure + schema-doc sync check | Development only |
| `validate_canonical_references.py` | Canonical reference path validator | Development only |

## Primary consumers
- Runtime turn execution (`emergence_cli.py`, `validate_state.py`).
- Development quality flows (`validate_reference_freshness.py`, `validate_docs_structure.py`, `validate_canonical_references.py`).
