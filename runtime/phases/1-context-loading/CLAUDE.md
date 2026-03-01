# Phase 1 — Context Loading

Load game state, scene, lore, and world context before any action interpretation.

## When This Phase Runs
- Start of every turn
- Start of every session
- When setting up a new game

## Mandatory Steps
1. Read `state.json` — character, scene, world, clocks, chronicle
2. Read current scene context from `current_scene` in state
3. Load relevant lore when player references game-specific content
4. Load hard rules and GM protocol (always-load references)

## Content To Create

Populate this phase with your game's content:

- **`references/`** — Hard rules, GM protocol, character creation rules
- **`lore/`** — World setting, geography, factions, creatures
- **`skills/`** — State loading, lore loading, scene context skills
- **`assets/`** — Templates (world state, character creation)
