# Runtime — Content Inventory

## Root Files
| File | Purpose |
|---|---|
| `CLAUDE.md` | Runtime governance — GM turn pipeline |
| `turn-loop.md` | Turn loop contract — mandatory 8-step sequence |
| `play-runbook.md` | Operational runbook — how to execute turns |
| `state.json` | Canonical game state (single source of truth) |

## Pipeline Phases
| Directory | Phase | Purpose |
|---|---|---|
| `phases/1-context-loading/` | Context Loading | Load state, scene, lore |
| `phases/2-action-interpretation/` | Action Interpretation | Classify action, select CLI |
| `phases/3-resolution/` | Mechanical Resolution | Execute CLI scripts |
| `phases/4-narrative/` | Narrative Translation | Translate to narrative |
| `phases/5-persistence/` | State Persistence | Update state.json |
| `phases/6-validation/` | Validation | Verify correctness |

## Entry Point Scripts
| File | Purpose |
|---|---|
| `scripts/emergence_cli.py` | Unified CLI dispatcher |
| `scripts/validate_state.py` | State JSON validator |
| `scripts/validate_canonical_references.py` | Canonical reference path validator |
| `scripts/validate_reference_freshness.py` | Reference path checker |
| `scripts/validate_turn_input.py` | Turn input validator |
| `scripts/validate_turn_receipt.py` | Turn receipt validator |
| `scripts/validate_docs_structure.py` | Documentation structure validator |

## Other Directories
| Directory | Purpose |
|---|---|
| `schemas/` | JSON Schema definitions (`state.schema.json`) |
| `tests/` | Validation test suite |
