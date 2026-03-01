# Execution Plan: XP Award, Level-Up, and Game-Start CLI Commands

- **Owner:** Claude
- **Status:** In Progress
- **Start Date:** 2026-02-22
- **Target Date:** 2026-02-22
- **Related:** `runtime/phases/3-resolution/skills/combat/combat-exit.md`, `runtime/phases/3-resolution/skills/downtime/training.md`, `runtime/phases/1-context-loading/skills/new-game-setup.md`

---

## Objective

Add three missing CLI commands that the existing runtime documentation references but that don't exist:

1. **`award-xp`** — Deterministic XP calculation from encounter data. Called at combat-exit and milestone events.
2. **`level-up`** — Threshold check + level bump + derived stat recalculation + reward summary.
3. **`game-start`** — Generates opening scene after session-zero + character creation, ensuring `current_scene` is populated before first turn.

Also fix the `character` CLI's `xp.next_level` → `xp.next` field naming to match the state schema.

---

## Design Decisions

| # | Decision | Rationale |
|---|---|---|
| 1 | XP formula: `base_xp × difficulty_multiplier` with base from creature threat level | Needs to be deterministic and seedable; ties to existing threat_level field |
| 2 | Level-up is a separate command from character generation | `character` creates from scratch; `level-up` progresses from existing state |
| 3 | `game-start` wraps `scene` CLI with sensible defaults | First scene should be exploration type, threat_level 1-2, in starting location |
| 4 | All three commands output JSON for artifact population | Consistent with every other CLI command |

---

## Surfaces Touched

- **Rules logic:** New functions in character.py (level-up math), new xp module, game-start wrapper
- **CLI:** Three new subcommands in emergence_cli.py + fix character command XP field
- **State schema:** No schema changes needed (xp.current/xp.next already defined)
- **Tests:** New test file for XP/level-up

---

## Implementation Steps

### Step 1: Add XP award system
- Create `runtime/phases/3-resolution/skills/core/scripts/xp.py`
- XP formula based on progression.md: `XP_for_next = 500 × 1.6^(level-1)`
- Award formula: base XP from creature threat level, scaled by encounter difficulty
- Add `award-xp` subcommand to emergence_cli.py

### Step 2: Add level-up command
- Add `level_up()` function to character.py
- Checks XP threshold, bumps level, recalculates derived stats
- Reports rewards due (attribute points, talent slots, form slots, passive triggers, evolution triggers)
- Add `level-up` subcommand to emergence_cli.py

### Step 3: Add game-start command
- Add `game-start` subcommand that generates an opening scene with safe defaults
- Outputs a valid `current_scene` object matching the schema
- References the character's starting location from session-zero

### Step 4: Fix XP field naming
- Change `emergence_cli.py` line 113: `"next_level"` → `"next"`

### Step 5: Tests
- Add test for XP calculation (formula matches progression.md table)
- Add test for level-up threshold detection
- Add test for game-start output schema compliance
- Run full test suite

---

## Done Criteria

- [ ] `emergence_cli.py award-xp` exists and returns deterministic XP amounts
- [ ] `emergence_cli.py level-up` exists and detects/applies level progression
- [ ] `emergence_cli.py game-start` exists and produces a valid opening scene
- [ ] `character` command outputs `xp.next` (not `xp.next_level`)
- [ ] All existing tests still pass
- [ ] New tests cover the three new commands
