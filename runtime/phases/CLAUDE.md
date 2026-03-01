# Phase System — Operating Instructions

Scope: `runtime/phases/`

## Purpose

The GM turn is a 6-phase pipeline. Each phase has its own directory with `CLAUDE.md` (instructions) and `index.md` (content inventory). All resources (references, lore, scripts, tables) are co-located within their owning phase.

## Pipeline Phases

| # | Phase | Directory | Purpose |
|---|---|---|---|
| 1 | Context Loading | `1-context-loading/` | Read state, scene, lore |
| 2 | Action Interpretation | `2-action-interpretation/` | Classify action, select CLI command |
| 3 | Mechanical Resolution | `3-resolution/` | Execute CLI scripts, parse JSON output |
| 4 | Narrative Translation | `4-narrative/` | Translate mechanics to narrative |
| 5 | State Persistence | `5-persistence/` | Update state.json |
| 6 | Validation | `6-validation/` | Verify correctness |

## How to Use

1. Process phases in order (1 through 6) for every turn.
2. Load each phase's `CLAUDE.md` for mandatory steps.
3. Load specific `skills/*.md` files as needed.
4. Phase 3 has domain sub-groups — load the relevant domain.

## Phase 3 Domain Navigation

Phase 3 is the largest phase. Organize mechanics into domains:
- `3-resolution/skills/<domain>/` — each domain has its own scripts, tables, references, and skill files

Create domains as needed for your game (e.g., core, combat, exploration, social, downtime, world-building).
