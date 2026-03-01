# Phase 3 — Mechanical Resolution: Content Inventory

All game mechanics are resolved through emergence_cli.py subcommands. Scripts and tables are physically co-located with their domain skills.

This phase is empty — populate with your game's domain sub-groups.

## Domain Structure Pattern

Each domain lives in `skills/<domain-name>/` with:
- `index.md` — domain content inventory
- `scripts/` — Python domain logic (auto-added to sys.path)
- `tables/` — Data tables (auto-added to sys.path)
- `references/` — Domain reference documentation
- Skill `.md` files — Operational procedures

## Suggested Domains

| Domain | Purpose |
|---|---|
| core | Dice, conditions, character stats, base mechanics |
| combat | Attack resolution, creatures, behavior AI |
| exploration | Scene generation, terrain, loot |
| social | NPCs, factions, diplomacy |
| downtime | Rest, training, crafting |
| world-building | World simulation, faction evolution |
