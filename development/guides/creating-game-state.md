# Creating Your Game State

The game state (`runtime/state.json`) is the single source of truth for your campaign. It conforms to `runtime/schemas/state.schema.json` and is validated by `runtime/scripts/validate_state.py`. This guide walks through extending the template state for your game.

## Template State Structure

The template provides a minimal, game-agnostic state with these top-level keys:

| Key | Type | Purpose |
|---|---|---|
| `schema_version` | string | Semver of state structure (currently `6.0.0`) |
| `content_version` | string | Semver of your game content |
| `meta` | object | Session tracking (`last_played`, `session_number`) |
| `character` | object | Player character (template: just `name` + `level`) |
| `world` | object | World-level containers (open) |
| `current_scene` | object | Active scene (`scene_id`, `location`, `region`, `threat_level`, `scene_type`) |
| `campaign` | object | Campaign metadata (`name`, `start_date`, `current_day`, `current_time`, `current_location`) |
| `current_day` / `current_time` | int/string | Top-level copies (must match `campaign.*`) |
| `clocks` | array | Scene-level story clocks |
| `world_situation` | object | World-level situation tracking (open — define your own structure) |
| `inter_group_relations` | array | Relations between factions/threats |
| `pc_standing` | array | Player reputation with factions |
| `human_factions` | array | Faction definitions with clocks |
| `external_threats` | array | Threat definitions with clocks |
| `meta_clocks` | array | World-level meta clocks |
| `faction_relationships` | array | Faction-to-faction complications |
| `known_npcs` | array | Discovered NPCs |
| `known_locations` | array | Discovered locations |
| `campaign_arcs` | array | Story arcs |
| `active_quests` | array | Active quest tracking |
| `chronicle` | array | Event log |
| `clock_log` | array | Clock change log |
| `world_pulse` | object | World news/rumors/trends |
| `last_played` | string | ISO-8601 timestamp |

## Step 1: Design Your Character Model

The template character has only `name` and `level`. Add your game's fields:

### Resource Pools

Use the `{current, max}` pattern for any depletable resource:

```json
"character": {
  "name": "Hero",
  "level": 1,
  "hp": { "current": 20, "max": 20 },
  "stamina": { "current": 10, "max": 10 },
  "mana": { "current": 5, "max": 5 }
}
```

### Attributes

Define your game's ability scores as a nested object:

```json
"attributes": {
  "strength": 14,
  "dexterity": 12,
  "constitution": 13,
  "intelligence": 10,
  "wisdom": 11,
  "charisma": 8
}
```

### Equipment and Inventory

```json
"equipment": {
  "weapon": "Iron Sword",
  "armor": "Leather Vest",
  "shield": null
},
"inventory": [
  { "name": "Health Potion", "qty": 2 },
  { "name": "Torch", "qty": 3 }
]
```

## Step 2: Design Your World Situation

`world_situation` is a free-form object. Structure it to match your setting:

**Fantasy kingdom:**
```json
"world_situation": {
  "kingdom": { "stability": "declining", "ruler": "absent" },
  "regions": {
    "northlands": { "control": "contested", "threats": ["frost_giants"] },
    "capital": { "control": "stable", "trade": "active" }
  }
}
```

**Post-apocalyptic city:**
```json
"world_situation": {
  "city_wide": { "resources": "scarce", "morale": "low" },
  "districts": {
    "downtown": { "control": "raiders", "danger": "high" },
    "harbor": { "control": "trade_guild", "danger": "moderate" }
  }
}
```

**Space station:**
```json
"world_situation": {
  "station_status": { "hull_integrity": 85, "oxygen": "stable" },
  "sectors": {
    "engineering": { "status": "damaged", "crew": 3 },
    "bridge": { "status": "operational", "crew": 5 }
  }
}
```

## Step 3: Update the Schema

Edit `runtime/schemas/state.schema.json` to formalize your additions:

1. Extend the `character` definition with `required` fields and property types
2. Add game-specific `$defs` for new object types
3. Keep `additionalProperties: true` on character while iterating, then lock it down

## Step 4: Update the Validator

Edit `runtime/scripts/validate_state.py`:

1. Add your attributes to the `_validate_character()` function
2. Add resource pool validation using `_validate_resource_pool()`
3. Add any game-specific invariants (e.g., "spell slots can't exceed level")

## Step 5: Update the Tests

Edit `runtime/tests/test_state_schema.py`:

1. Add mutation tests for every new required field
2. Add range-check tests for bounded values
3. Add cross-reference tests for any new ID relationships

## Step 6: Validate

```bash
python runtime/scripts/validate_state.py runtime/state.json
python runtime/tests/run_all_tests.py 1
```

## Integration Touchpoints

When you extend the state, also update:

- `development/quality/state-schema-migration-notes.md` — add migration guidance
- `development/quality/reference-freshness.md` — update commit hashes
- `runtime/phases/5-persistence/` — persistence procedures need to know about new fields
- Hooks (if any) — state context injection needs to extract new fields

> Full integration guide: `development/change-integration-checklist.md` §5
