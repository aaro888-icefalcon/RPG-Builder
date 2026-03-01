# Phase 6 — Validation

Verify response completeness and correctness.

## When This Phase Runs
- After state persistence (Phase 5)
- Validation hooks fire automatically on every response

## Manual Validation (On-Demand)
- `python scripts/validate_state.py state.json` — full state schema check
- `python scripts/validate_reference_freshness.py` — reference path check

## Content To Create

- **`skills/pre-turn-validation.md`** — Pre-turn state validation procedures
- **`skills/response-gate.md`** — Ensure response completeness
