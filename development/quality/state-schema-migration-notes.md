# Campaign State Migration Notes (Schema 5.0.0)

Use this when upgrading older campaign `state.json` files to the current schema expected by:

- `scripts/world_tick.py`
- `scripts/scene.py`
- `scripts/diplomacy.py`
- `scripts/emergence_cli.py` world/session commands

## 1) Add explicit version fields

Older files often used a single `version` field. Replace it with:

- `schema_version` (state shape compatibility)
- `content_version` (game/content build)

Example:

```json
{
  "schema_version": "5.0.0",
  "content_version": "4.5.12"
}
```

## 2) Keep both campaign and top-level day/time fields

Current scripts read both styles depending on command path.

Required:

- `campaign.current_day` and `campaign.current_time` (used by world tick)
- top-level `current_day` and `current_time` (used by scene generation)

If one side exists, copy values to the other side.

## 3) Ensure required world containers exist

Add empty defaults if missing:

- `clocks: []`
- `world_situation: {"nyc_wide": {}, "neighborhoods": {}, "regions": {}}`
- `inter_group_relations: []`
- `pc_standing: []`
- `human_factions: []`
- `external_threats: []`
- `meta_clocks: []`
- `faction_relationships: []`

## 4) Normalize relation and standing entries

`inter_group_relations` entries should contain:

- `faction_a` (string)
- `faction_b` (string)
- `relation_type` (string)
- `history` (array)

`pc_standing` entries should contain:

- `faction_id` (string)
- `rank` (string)
- `disposition` (string)
- `reputation_events` (array)

## 5) Remove obsolete keys

Delete legacy top-level keys that are no longer part of current schema:

- `version`
- `entropy`
- `factions`
- `threats`
- `relations`

## 6) Validate after migration

Run:

```bash
python scripts/validate_state.py <path-to-state.json>
```

Validation must pass before starting/continuing a campaign.
