# Runtime — Play Mode

Scope: `runtime/`

This file governs high-fidelity game runtime execution. It is operational by design and intentionally strict.

## Fidelity Pledge

- Run turns using CLI scripts and rules as written.
- Do not improvise mechanics, rolls, damage, loot, or hidden state updates.
- If a required script is missing/unclear/failing, halt and report the gap.

## Truth Model (authority order)

1. Canonical state (`state.json`) — absolute truth; must conform to `schemas/state.schema.json`
2. CLI output (`emergence_cli.py` results) — mechanics evidence
3. Game-specific hard rules — define in `phases/1-context-loading/references/hard-rules.md`
4. Game-specific GM protocol — define in `phases/1-context-loading/references/gm-protocol.md`
5. This file — operational governance

## GM Turn Pipeline

Every turn follows this 6-phase pipeline in strict order:

| Phase | Directory | Purpose |
|---|---|---|
| 1. Context Loading | `phases/1-context-loading/` | Read state, scene, lore |
| 2. Action Interpretation | `phases/2-action-interpretation/` | Classify action, select CLI command |
| 3. Mechanical Resolution | `phases/3-resolution/` | Execute CLI, parse JSON results |
| 4. Narrative Translation | `phases/4-narrative/` | Translate mechanics to narrative |
| 5. State Persistence | `phases/5-persistence/` | Update state.json |
| 6. Validation | `phases/6-validation/` | Verify completeness |

Each phase has its own `CLAUDE.md` with detailed instructions and an `index.md` with content inventory.

## Hard Rules (Template)

Define your game's non-negotiable rules. Suggested starting set:

1. Never auto-resolve player actions — always wait for explicit input.
2. Execute scripts, never estimate results.
3. Use deterministic mechanics — record RNG seeds.
4. Death is real — do not shield the player from lethal outcomes.

> Create your full hard rules at: `phases/1-context-loading/references/hard-rules.md`

## Forced Consequences

When the CLI returns a forced consequence, it is **BINDING**. No substitution, no softening, no reinterpretation. Narrate the exact consequence the CLI selected.

## Narrative Principles (Template)

Define your game's narrative tone. Examples:
- What is the world's default disposition toward the player?
- How scarce are resources?
- What is the tone (gritty, heroic, comedic)?
- How do NPCs behave by default?

> Create your narrative guide at: `phases/4-narrative/references/narration-mappings.md`

## Entry Points (scripts/ root)

| Script | Purpose |
|---|---|
| `scripts/emergence_cli.py` | CLI dispatcher — all mechanics flow through this |
| `scripts/validate_state.py` | Canonical state validation (against `schemas/state.schema.json`) |

Domain scripts and tables live inside `phases/3-resolution/skills/<domain>/scripts/` and `tables/`.

## No Silent Repairs

Do not patch around failures inside runtime mode. If a gap is discovered, halt and open a development-mode task.

## Determinism

Record RNG seed in state and turn receipt. Re-running with same seed/inputs produces stable outputs.
