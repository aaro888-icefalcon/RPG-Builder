# Campaign State Migration Notes (Schema 6.0.0)

Use this when upgrading campaign `state.json` files to the current template schema.

## 1) Schema version

Current schema version is `6.0.0` (game-agnostic template). Update `schema_version` in your state file:

```json
{
  "schema_version": "6.0.0",
  "content_version": "0.0.1"
}
```

## 2) Keep both campaign and top-level day/time fields

Required:

- `campaign.current_day` and `campaign.current_time`
- top-level `current_day` and `current_time`

Both sides must agree. The sync validator checks this.

## 3) Ensure required world containers exist

Add empty defaults if missing:

- `clocks: []`
- `world_situation: {}` (open object — define your own structure)
- `inter_group_relations: []`
- `pc_standing: []`
- `human_factions: []`
- `external_threats: []`
- `meta_clocks: []`
- `faction_relationships: []`

## 4) Character is minimal

Template schema requires only `name` (string) and `level` (integer 0-100) on the character object. Additional properties are allowed — add your game's attributes, resource pools, equipment, and abilities as needed.

## 5) World situation is open

`world_situation` is now an open `{}` object. Define whatever structure your game needs (regions, political state, weather, etc.). No sub-keys are required by the template schema.

## 6) Remove obsolete keys

Delete legacy top-level keys if present:

- `version` (replaced by `schema_version` + `content_version`)
- `entropy` (legacy pressure system)
- `factions`, `threats`, `relations` (ambiguous aliases)

## 7) Validate after migration

Run:

```bash
python scripts/validate_state.py <path-to-state.json>
```

Validation must pass before starting/continuing a campaign.
