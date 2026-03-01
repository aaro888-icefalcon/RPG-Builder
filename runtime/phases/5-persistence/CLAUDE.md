# Phase 5 — State Persistence

Update state.json with all mechanical changes from the current turn.

## When This Phase Runs
- After narrative (Phase 4) is complete
- Before validation (Phase 6)

## Mandatory Steps
1. Update character stats (HP, resources, conditions)
2. Update current scene (location, NPCs, threats)
3. Update world state (clocks, faction states, relationships)
4. Update chronicle with turn summary
5. Update meta.last_played timestamp
6. Write state.json

## Key Resources
- Schema contract: `schemas/state.schema.json` — written state must conform
- Validator: `scripts/validate_state.py` — run after every state write

## Content To Create

- **`skills/state-persistence.md`** — Detailed persistence procedures
- **`turn-receipt-template.json`** — Turn receipt format template
