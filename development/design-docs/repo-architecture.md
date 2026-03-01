# Repository Architecture

This document defines the canonical structure and content boundaries for the repository.

## Top-Level Layout

| Directory | Intent |
| --- | --- |
| `runtime/` | Game system root — 6-phase GM pipeline, scripts, tests, game state |
| `development/` | Engineering workflow, governance, planning, design docs, quality |
| `archives/` | Archived backups of legacy artifacts |

## Runtime Structure

The runtime is organized as a 6-phase GM pipeline. Each phase directory contains a `CLAUDE.md` (operating instructions) and an `index.md` (content inventory).

| Directory | Phase | Content |
| --- | --- | --- |
| `runtime/phases/1-context-loading/` | Context Loading | State, lore, scene context, hard-rules, gm-protocol, creation, awakening, aspects-archetypes |
| `runtime/phases/2-action-interpretation/` | Action Interpretation | Action classification, CLI command selection, cli-reference |
| `runtime/phases/3-resolution/` | Mechanical Resolution | Domain-grouped skills, scripts, tables, and references (see below) |
| `runtime/phases/4-narrative/` | Narrative Translation | Narration examples, narration mappings, character-sheet and scene templates |
| `runtime/phases/5-persistence/` | State Persistence | State write procedures, turn-receipt template |
| `runtime/phases/6-validation/` | Validation | Response gate, state validator, reference-freshness validator |

### Phase 3 Domain Groups

Phase 3 organizes mechanical resolution by gameplay domain under `runtime/phases/3-resolution/skills/`:

| Domain | Skills | Scripts | Tables |
| --- | --- | --- | --- |
| `core/` | forced-consequence, move-resolution | dice.py, conditions.py, character.py | — |
| `combat/` | attack-resolution, combat-setup, combat-exit, enemy-turn, player-turn, turn-start, round-end | combat.py, behavior.py, technique_registry.py | — |
| `exploration/` | scene-generation, scene-pressure, terrain-navigation, scavenging-loot, creature-preloading, perception-investigation | — | — |
| `social/` | diplomacy, relationship-update, standing-update, npc-agenda-check, arena-resolution | diplomacy.py | social_encounters.py, situation_tags.py |
| `downtime/` | downtime-activities, crafting, rest, training | — | downtime_activities.py |
| `world-building/` | world-tick, clock-tick, world-pulse, faction-update, adventure-hook | moves.py | world_situation.py, faction_actions.py |

### Other Runtime Directories

| Directory | Intent | Allowed file types |
| --- | --- | --- |
| `runtime/scripts/` | CLI entry point (`emergence_cli.py`) and standalone validators | `.py` |
| `runtime/tests/` | Balance and validation test suites | `.py`, `.json` |
| `runtime/turn_receipts/` | Generated turn receipt records | `.json` |

### Runtime Navigation Files

| File | Role |
| --- | --- |
| `runtime/CLAUDE.md` | Runtime operating instructions |
| `runtime/index.md` | Runtime content inventory and navigation hub |
| `runtime/turn-loop.md` | 6-phase turn execution procedure |
| `runtime/play-runbook.md` | Session-level play operations guide |
| `runtime/phases/phase-manifest.md` | Machine-readable phase-to-content mapping |
| `runtime/scripts/CLAUDE.md` | Script registry and CLI reference |

## Development Structure

| Directory | Intent |
| --- | --- |
| `development/design-docs/` | Architecture decisions, design principles, decision log |
| `development/quality/` | CI commands, reference-freshness policy, state-schema migration notes |
| `development/ongoing-plans/` | Execution plans with lifecycle (active → completed) and analysis artifacts |

## Enforcement Notes

- Add new content to the phase directory matching the artifact's pipeline stage. Within phase 3, place content in the matching domain group.
- Every directory must maintain an `index.md` as the discoverability entry point and a `CLAUDE.md` for operating instructions where applicable.
- If a new file type is needed, update this architecture document in the same change.
- Stable ordering in machine outputs: any randomness must be seedable with the seed recorded in state/turn records.

## Implementation History

1. **Original reorganization** (2025): Repository moved from nested `Claude Code/emergence-rpg-v45/` to flat `runtime/` layout with domain-first folders (`references/`, `lore/`, `tables/`, `assets/`, `scripts/`, `tests/`). See [repo-structure-breakdown](../ongoing-plans/plans/completed/repo-structure-breakdown.md).
2. **Phase-oriented restructuring** (2026-02): Domain-first layout replaced by 6-phase GM pipeline. Content relocated into `runtime/phases/1-6` with domain sub-groups under phase 3. See [phase-oriented-runtime-reorganization](../ongoing-plans/plans/completed/phase-oriented-runtime-reorganization.md) and [repository-hierarchy-reorganization-plan](../ongoing-plans/plans/completed/repository-hierarchy-reorganization-plan.md).
