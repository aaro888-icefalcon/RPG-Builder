# Creating Skills and Mechanics

Skills are the game-specific content that populates the 6-phase GM pipeline. Mechanics are the Python scripts that compute deterministic outcomes. This guide covers how to create both and wire them into the runtime.

## Architecture Overview

```
runtime/phases/3-resolution/skills/
├── core/           — Dice, conditions, character math
├── combat/         — Combat loop, enemies, behavior AI
├── exploration/    — Scene generation, terrain, loot
├── social/         — NPCs, factions, diplomacy
├── downtime/       — Rest, training, crafting
└── world-building/ — World tick, faction evolution
```

Each domain follows an identical structure:

```
skills/<domain>/
├── CLAUDE.md          — Operating instructions for this domain
├── index.md           — Skill inventory and reference map
├── scripts/           — Python scripts (mechanics engine)
├── tables/            — Data tables (JSON/CSV)
└── references/        — Canonical rule documents
```

## Step 1: Choose Your First Mechanic

Start with the smallest mechanic that enables gameplay. Good first choices:

- **Dice roll / action resolution** — the core mechanic everything else builds on
- **Character creation** — generates a starting character
- **Scene generation** — creates the environment for play

## Step 2: Write the Script

Create a Python script in the appropriate domain. Scripts must:

1. Accept arguments via CLI (argparse)
2. Output structured JSON to stdout
3. Use seedable randomness (record seed in output)
4. Have zero external dependencies (stdlib only)

**Example: `scripts/roll.py`**

```python
#!/usr/bin/env python3
"""Roll dice with modifiers. Core action resolution mechanic."""

import argparse
import json
import random
import sys

def roll_dice(num_dice, sides, modifier, seed=None):
    rng = random.Random(seed)
    rolls = [rng.randint(1, sides) for _ in range(num_dice)]
    total = sum(rolls) + modifier
    return {
        "rolls": rolls,
        "modifier": modifier,
        "total": total,
        "seed": seed or rng.getstate()[1][0],
    }

def main():
    parser = argparse.ArgumentParser(description="Roll dice")
    parser.add_argument("--dice", default="2d6", help="Dice notation (e.g., 2d6)")
    parser.add_argument("--modifier", type=int, default=0)
    parser.add_argument("--seed", type=int, default=None)
    args = parser.parse_args()

    num, sides = args.dice.split("d")
    result = roll_dice(int(num), int(sides), args.modifier, args.seed)
    print(json.dumps(result, indent=2))

if __name__ == "__main__":
    main()
```

## Step 3: Register in the CLI Dispatcher

Edit `runtime/scripts/emergence_cli.py` to add your command:

```python
# In COMMANDS dict:
COMMANDS = {
    "roll": {
        "script": "phases/3-resolution/skills/core/scripts/roll.py",
        "description": "Roll dice with modifiers",
    },
    # ... more commands
}
```

## Step 4: Write the Skill Document

Create a skill `.md` file that tells the AI GM when and how to use the mechanic. Place it in the owning phase directory.

**Example: `phases/3-resolution/skills/core/action-resolution.md`**

```markdown
# Action Resolution

## When to use
Any time a player attempts an action with uncertain outcome.

## CLI command
`emergence_cli.py roll --dice 2d6 --modifier <stat_modifier>`

## Interpreting results
| Total | Outcome |
|---|---|
| 10+ | Full success |
| 7-9 | Partial success (complication) |
| 6- | Failure (consequence) |

## Required state updates
- Update `chronicle` with the action and outcome
- Apply any mechanical consequences (HP loss, clock ticks, etc.)

## Hooks that enforce this
- (list any hooks that validate this mechanic was used correctly)
```

## Step 5: Create Reference Documents

Phase 1 reference docs define the rules the GM loads before responding:

**`phases/1-context-loading/references/hard-rules.md`** — non-negotiable rules:
- When to roll dice vs. auto-succeed
- What the player can and cannot do
- Death and defeat conditions

**`phases/1-context-loading/references/gm-protocol.md`** — adjudication guidance:
- How to interpret player intent
- Position and effect levels
- Consequence selection

## Step 6: Wire Into the Pipeline

### Phase index files

Update `phases/<N>/index.md` to list the new skill:

```markdown
| Skill | Script | Purpose |
|---|---|---|
| Action Resolution | `skills/core/scripts/roll.py` | Core dice mechanic |
```

### Phase manifest

Update `runtime/phases/phase-manifest.md`:

```markdown
### Phase 3 — Resolution
- cli_commands: roll
- references: core/action-resolution.md
- scripts: core/scripts/roll.py
```

### Script registry

Update `runtime/scripts/CLAUDE.md`:

```markdown
| Command | Script | Domain |
|---|---|---|
| roll | phases/3-resolution/skills/core/scripts/roll.py | core |
```

## Step 7: Add Tests

Create a test file for your mechanic:

```python
# runtime/tests/test_roll.py
def test_roll_deterministic():
    """Same seed produces same result."""
    result1 = roll_dice(2, 6, 0, seed=42)
    result2 = roll_dice(2, 6, 0, seed=42)
    assert result1["total"] == result2["total"]
```

Register it in `runtime/tests/run_all_tests.py`.

## Step 8: (Optional) Add Enforcement Hooks

If the mechanic needs enforcement, create hooks:

- **PreToolUse hook** — validate inputs before execution
- **PostToolUse hook** — inject parsing guidance from output
- **Stop hook** — ensure the mechanic was used when required

See `development/guides/creating-hooks.md` for hook creation details.

## Expansion Pattern

Once your first mechanic works end-to-end, expand by domain:

1. **Core** — dice, conditions, character math, XP/leveling
2. **Combat** — attack resolution, enemy generation, behavior AI
3. **Exploration** — scene generation, loot tables, environmental hazards
4. **Social** — NPC generation, dialogue, faction reputation
5. **Downtime** — rest mechanics, crafting, training
6. **World-building** — world tick, faction evolution, clock management

Each domain follows the same pattern: script + skill doc + reference + test + registration.

## Integration Checklist

- [ ] Script created in `phases/3-resolution/skills/<domain>/scripts/`
- [ ] Command registered in `emergence_cli.py`
- [ ] Skill document created in owning phase
- [ ] Phase `index.md` and `CLAUDE.md` updated
- [ ] `phase-manifest.md` updated
- [ ] `scripts/CLAUDE.md` updated
- [ ] Test created and registered
- [ ] Validators pass: `python runtime/tests/run_all_tests.py 1`
- [ ] Reference freshness updated if new reference docs created

> Full integration guide: `development/change-integration-checklist.md`
