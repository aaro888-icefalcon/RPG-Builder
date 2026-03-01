#!/usr/bin/env python3
"""
Validate campaign world-state JSON — deep structural and invariant checks.

Layers:
  1. Required keys and types (top-level and nested)
  2. Domain-specific structure (character, factions, clocks, NPCs, etc.)
  3. Cross-reference integrity (faction IDs, NPC IDs across sections)
  4. Mechanical invariants (clock consistency, resource pools)
  5. Sync checks (duplicated fields must agree)

Zero external dependencies — uses only the Python standard library.

Template version: game-agnostic. Character validation checks only name and
level. Extend _validate_character() with your game's fields.
"""

import argparse
import json
import sys
from pathlib import Path


# ---------------------------------------------------------------------------
# Layer 1 — Top-level structure
# ---------------------------------------------------------------------------

REQUIRED_TOP_LEVEL_TYPES = {
    "schema_version": str,
    "content_version": str,
    "meta": dict,
    "character": dict,
    "world": dict,
    "current_scene": dict,
    "campaign": dict,
    "current_day": int,
    "current_time": str,
    "clocks": list,
    "world_situation": dict,
    "inter_group_relations": list,
    "pc_standing": list,
    "human_factions": list,
    "external_threats": list,
    "meta_clocks": list,
    "faction_relationships": list,
    "known_npcs": list,
    "known_locations": list,
    "campaign_arcs": list,
    "active_quests": list,
    "chronicle": list,
    "clock_log": list,
    "world_pulse": dict,
    "last_played": str,
}

FORBIDDEN_TOP_LEVEL_KEYS = {
    "version",        # replaced by schema_version + content_version
    "entropy",        # legacy global pressure system
    "factions",       # ambiguous legacy aliases
    "threats",        # ambiguous legacy aliases
    "relations",      # ambiguous legacy aliases
}


def _is_type(value, expected_type):
    if expected_type is int:
        return isinstance(value, int) and not isinstance(value, bool)
    return isinstance(value, expected_type)


def _check_required(obj, fields, path, errors):
    """Check that *obj* (dict) has all *fields* with correct types."""
    for key, typ in fields.items():
        if key not in obj:
            errors.append(f"{path}.{key}: missing")
            continue
        val = obj[key]
        if isinstance(typ, tuple):
            if not any(_is_type(val, t) if t is not None else val is None for t in typ):
                names = "/".join(t.__name__ if t is not None else "null" for t in typ)
                errors.append(f"{path}.{key}: expected {names}, got {type(val).__name__}")
        else:
            if not _is_type(val, typ):
                errors.append(f"{path}.{key}: expected {typ.__name__}, got {type(val).__name__}")


def _check_range(value, low, high, path, errors):
    """Check that an integer *value* is in [low, high]."""
    if isinstance(value, int) and not isinstance(value, bool):
        if value < low or value > high:
            errors.append(f"{path}: {value} out of range [{low}, {high}]")


# ---------------------------------------------------------------------------
# Layer 2 — Domain-specific structure
# ---------------------------------------------------------------------------

VALID_SIGNIFICANCE = {"minor", "moderate", "major", "critical"}
VALID_CLOCK_STATUS = {"active", "completed", "paused", "cancelled"}
VALID_NPC_STATUS = {"active", "dead", "missing", "departed"}
VALID_SCENE_TYPES = {"combat", "exploration", "social", "downtime", "travel"}
VALID_THREAT_STATUS = {"active", "completed", "dormant", "defeated"}


def _validate_resource_pool(pool, path, errors):
    """Validate a {current, max} resource pool."""
    if not isinstance(pool, dict):
        errors.append(f"{path}: expected dict, got {type(pool).__name__}")
        return
    _check_required(pool, {"current": int, "max": int}, path, errors)
    cur = pool.get("current")
    mx = pool.get("max")
    if isinstance(cur, int) and isinstance(mx, int):
        if cur < 0:
            errors.append(f"{path}.current: {cur} is negative")
        if mx < 1:
            errors.append(f"{path}.max: {mx} must be >= 1")
        if cur > mx:
            errors.append(f"{path}: current ({cur}) > max ({mx})")


def _validate_character(char, errors):
    """Validate character — template version checks only name and level.

    Extend this function with your game's character validation:
    - Resource pools (hp, stamina, mana, etc.)
    - Attributes and their ranges
    - Equipment slots
    - Abilities, forms, techniques
    """
    path = "character"
    _check_required(char, {"name": str, "level": int}, path, errors)

    level = char.get("level")
    if isinstance(level, int):
        _check_range(level, 0, 100, f"{path}.level", errors)


def _validate_current_scene(scene, errors):
    path = "current_scene"
    _check_required(scene, {
        "scene_id": str, "location": str, "region": str,
        "threat_level": int, "scene_type": str,
    }, path, errors)

    tl = scene.get("threat_level")
    if isinstance(tl, int):
        _check_range(tl, 0, 10, f"{path}.threat_level", errors)

    st = scene.get("scene_type")
    if isinstance(st, str) and st not in VALID_SCENE_TYPES:
        errors.append(f"{path}.scene_type: '{st}' not in {VALID_SCENE_TYPES}")


def _validate_meta(meta, errors):
    path = "meta"
    _check_required(meta, {"last_played": str, "session_number": int}, path, errors)
    sn = meta.get("session_number")
    if isinstance(sn, int) and sn < 0:
        errors.append(f"{path}.session_number: {sn} is negative")


def _validate_chronicle(chronicle, errors):
    for idx, entry in enumerate(chronicle):
        path = f"chronicle[{idx}]"
        if not isinstance(entry, dict):
            errors.append(f"{path}: expected dict, got {type(entry).__name__}")
            continue
        _check_required(entry, {
            "day": int, "time": str,
            "event": str, "significance": str, "tags": list,
        }, path, errors)

        sig = entry.get("significance")
        if isinstance(sig, str) and sig not in VALID_SIGNIFICANCE:
            errors.append(f"{path}.significance: '{sig}' not in {VALID_SIGNIFICANCE}")

        tags = entry.get("tags", [])
        if isinstance(tags, list):
            for tidx, tag in enumerate(tags):
                if not isinstance(tag, str):
                    errors.append(f"{path}.tags[{tidx}]: expected str, got {type(tag).__name__}")

        day = entry.get("day")
        if isinstance(day, int) and day < 1:
            errors.append(f"{path}.day: {day} must be >= 1")


def _validate_clock_log(clock_log, errors):
    for idx, entry in enumerate(clock_log):
        path = f"clock_log[{idx}]"
        if not isinstance(entry, dict):
            errors.append(f"{path}: expected dict, got {type(entry).__name__}")
            continue
        _check_required(entry, {
            "day": int, "clock": str,
            "change": str, "new_value": str, "reason": str,
        }, path, errors)


def _validate_known_npcs(npcs, errors):
    seen_ids = set()
    for idx, npc in enumerate(npcs):
        path = f"known_npcs[{idx}]"
        if not isinstance(npc, dict):
            errors.append(f"{path}: expected dict, got {type(npc).__name__}")
            continue
        _check_required(npc, {
            "id": str, "name": str, "faction": str,
            "role": str, "disposition": str, "status": str,
        }, path, errors)

        npc_id = npc.get("id")
        if isinstance(npc_id, str):
            if npc_id in seen_ids:
                errors.append(f"{path}.id: duplicate NPC id '{npc_id}'")
            seen_ids.add(npc_id)

        status = npc.get("status")
        if isinstance(status, str) and status not in VALID_NPC_STATUS:
            errors.append(f"{path}.status: '{status}' not in {VALID_NPC_STATUS}")

        trust = npc.get("trust")
        if trust is not None and isinstance(trust, int):
            _check_range(trust, 0, 10, f"{path}.trust", errors)


def _validate_known_locations(locations, errors):
    seen_ids = set()
    for idx, loc in enumerate(locations):
        path = f"known_locations[{idx}]"
        if not isinstance(loc, dict):
            errors.append(f"{path}: expected dict, got {type(loc).__name__}")
            continue
        _check_required(loc, {
            "id": str, "name": str, "region": str,
            "threat_level": int, "discovered_day": int,
        }, path, errors)

        loc_id = loc.get("id")
        if isinstance(loc_id, str):
            if loc_id in seen_ids:
                errors.append(f"{path}.id: duplicate location id '{loc_id}'")
            seen_ids.add(loc_id)

        tl = loc.get("threat_level")
        if isinstance(tl, int):
            _check_range(tl, 0, 10, f"{path}.threat_level", errors)


def _validate_clock_shape(clock, path, errors):
    required = {"name": str, "current": int, "max": int}
    _check_required(clock, required, path, errors)

    cur = clock.get("current")
    mx = clock.get("max")
    if isinstance(cur, int) and isinstance(mx, int):
        if cur < 0:
            errors.append(f"{path}.current: {cur} is negative")
        if mx < 1:
            errors.append(f"{path}.max: {mx} must be >= 1")
        if cur > mx:
            errors.append(f"{path}: current ({cur}) > max ({mx})")

    status = clock.get("status")
    if isinstance(status, str) and status not in VALID_CLOCK_STATUS:
        errors.append(f"{path}.status: '{status}' not in {VALID_CLOCK_STATUS}")

    history = clock.get("history", [])
    if isinstance(history, list):
        for hidx, entry in enumerate(history):
            hp = f"{path}.history[{hidx}]"
            if isinstance(entry, dict):
                _check_required(entry, {
                    "day": int, "change": int,
                    "old": int, "new": int, "reason": str,
                }, hp, errors)

    if isinstance(history, list) and len(history) > 0 and isinstance(cur, int):
        last_entry = history[-1]
        if isinstance(last_entry, dict):
            last_new = last_entry.get("new")
            if isinstance(last_new, int) and last_new != cur:
                errors.append(
                    f"{path}: last history entry new ({last_new}) != current ({cur})"
                )

    portents = clock.get("portents", [])
    if isinstance(portents, list):
        for pidx, portent in enumerate(portents):
            pp = f"{path}.portents[{pidx}]"
            if isinstance(portent, dict):
                _check_required(portent, {
                    "at": int, "event": str,
                    "mechanical": str, "fired": bool,
                }, pp, errors)
                p_at = portent.get("at")
                p_fired = portent.get("fired")
                if (isinstance(p_at, int) and isinstance(p_fired, bool)
                        and isinstance(cur, int)):
                    if p_at <= cur and not p_fired:
                        errors.append(
                            f"{pp}: threshold ({p_at}) <= current ({cur}) "
                            f"but fired is false"
                        )


# ---------------------------------------------------------------------------
# Layer 3 — Cross-reference integrity
# ---------------------------------------------------------------------------

def _validate_cross_references(state, errors):
    """Check that IDs referenced across sections actually exist."""
    faction_ids = set()
    for f in state.get("human_factions", []):
        if isinstance(f, dict) and isinstance(f.get("id"), str):
            faction_ids.add(f["id"])

    threat_ids = set()
    for t in state.get("external_threats", []):
        if isinstance(t, dict) and isinstance(t.get("id"), str):
            threat_ids.add(t["id"])

    all_entity_ids = faction_ids | threat_ids

    for idx, standing in enumerate(state.get("pc_standing", [])):
        if not isinstance(standing, dict):
            continue
        fid = standing.get("faction_id")
        if isinstance(fid, str) and fid not in faction_ids:
            errors.append(
                f"pc_standing[{idx}].faction_id: '{fid}' not found in human_factions"
            )

    for idx, rel in enumerate(state.get("inter_group_relations", [])):
        if not isinstance(rel, dict):
            continue
        for side in ("faction_a", "faction_b"):
            eid = rel.get(side)
            if isinstance(eid, str) and eid not in all_entity_ids:
                errors.append(
                    f"inter_group_relations[{idx}].{side}: '{eid}' not found "
                    f"in human_factions or external_threats"
                )


# ---------------------------------------------------------------------------
# Layer 4 — Mechanical invariants (clock consistency)
# ---------------------------------------------------------------------------

def _validate_clock_invariants(state, errors):
    """Check clock-level invariants across all clock collections."""
    def _check_clock_completion(clock, path):
        status = clock.get("status")
        cur = clock.get("current")
        mx = clock.get("max")
        if status == "completed" and isinstance(cur, int) and isinstance(mx, int):
            if cur != mx:
                errors.append(
                    f"{path}: status is 'completed' but current ({cur}) != max ({mx})"
                )

    for idx, clock in enumerate(state.get("clocks", [])):
        if isinstance(clock, dict):
            _check_clock_completion(clock, f"clocks[{idx}]")

    for idx, clock in enumerate(state.get("meta_clocks", [])):
        if isinstance(clock, dict):
            _check_clock_completion(clock, f"meta_clocks[{idx}]")

    for fidx, faction in enumerate(state.get("human_factions", [])):
        if isinstance(faction, dict):
            clock = faction.get("clock")
            if isinstance(clock, dict):
                _check_clock_completion(clock, f"human_factions[{fidx}].clock")

    for tidx, threat in enumerate(state.get("external_threats", [])):
        if isinstance(threat, dict):
            clock = threat.get("clock")
            if isinstance(clock, dict):
                _check_clock_completion(clock, f"external_threats[{tidx}].clock")


# ---------------------------------------------------------------------------
# Layer 5 — Sync checks
# ---------------------------------------------------------------------------

def _validate_sync(state, errors):
    """Check that duplicated/mirrored fields are consistent."""
    campaign = state.get("campaign", {})
    if isinstance(campaign, dict):
        top_day = state.get("current_day")
        camp_day = campaign.get("current_day")
        if (isinstance(top_day, int) and isinstance(camp_day, int)
                and top_day != camp_day):
            errors.append(
                f"sync: current_day ({top_day}) != campaign.current_day ({camp_day})"
            )

        top_time = state.get("current_time")
        camp_time = campaign.get("current_time")
        if (isinstance(top_time, str) and isinstance(camp_time, str)
                and top_time != camp_time):
            errors.append(
                f"sync: current_time ('{top_time}') != campaign.current_time ('{camp_time}')"
            )


# ---------------------------------------------------------------------------
# Main validation entry point
# ---------------------------------------------------------------------------

def validate_state(state):
    """Run all validation layers. Returns list of error strings (empty = pass)."""
    errors = []

    # --- Layer 1: Forbidden + required top-level keys ---
    for key in sorted(FORBIDDEN_TOP_LEVEL_KEYS):
        if key in state:
            errors.append(f"{key}: forbidden obsolete top-level key")

    for key, typ in REQUIRED_TOP_LEVEL_TYPES.items():
        if key not in state:
            errors.append(f"{key}: missing required top-level key")
            continue
        if not _is_type(state[key], typ):
            errors.append(f"{key}: expected {typ.__name__}, got {type(state[key]).__name__}")

    allowed_keys = set(REQUIRED_TOP_LEVEL_TYPES.keys())
    for key in state:
        if key not in allowed_keys:
            errors.append(f"{key}: unexpected top-level key (typo?)")

    critical_keys = {"character", "campaign", "meta"}
    if any(k not in state or not isinstance(state.get(k), dict) for k in critical_keys):
        return errors

    # --- Layer 2: Domain-specific structure ---
    _validate_meta(state.get("meta", {}), errors)
    _validate_character(state["character"], errors)
    _validate_current_scene(state.get("current_scene", {}), errors)

    campaign = state.get("campaign", {})
    if isinstance(campaign, dict):
        _check_required(campaign, {
            "name": str, "start_date": str,
            "current_day": int, "current_time": str,
            "current_location": str,
        }, "campaign", errors)

    for idx, rel in enumerate(state.get("inter_group_relations", [])):
        path = f"inter_group_relations[{idx}]"
        if not isinstance(rel, dict):
            errors.append(f"{path}: expected dict, got {type(rel).__name__}")
            continue
        _check_required(rel, {
            "faction_a": str, "faction_b": str,
            "relation_type": str, "history": list,
        }, path, errors)

    for idx, standing in enumerate(state.get("pc_standing", [])):
        path = f"pc_standing[{idx}]"
        if not isinstance(standing, dict):
            errors.append(f"{path}: expected dict, got {type(standing).__name__}")
            continue
        _check_required(standing, {
            "faction_id": str, "rank": str,
            "disposition": str, "reputation_events": list,
        }, path, errors)

    seen_faction_ids = set()
    for idx, faction in enumerate(state.get("human_factions", [])):
        path = f"human_factions[{idx}]"
        if not isinstance(faction, dict):
            errors.append(f"{path}: expected dict, got {type(faction).__name__}")
            continue
        _check_required(faction, {
            "id": str, "name": str,
            "archetype": str, "goal": str, "clock": dict,
        }, path, errors)
        fid = faction.get("id")
        if isinstance(fid, str):
            if fid in seen_faction_ids:
                errors.append(f"{path}.id: duplicate faction id '{fid}'")
            seen_faction_ids.add(fid)
        if isinstance(faction.get("clock"), dict):
            _validate_clock_shape(faction["clock"], f"{path}.clock", errors)
        power = faction.get("power_level")
        if power is not None and isinstance(power, int):
            _check_range(power, 1, 10, f"{path}.power_level", errors)
        for nidx, npc_ref in enumerate(faction.get("npcs", [])):
            np = f"{path}.npcs[{nidx}]"
            if isinstance(npc_ref, dict):
                _check_required(npc_ref, {"id": str, "role": str}, np, errors)

    seen_threat_ids = set()
    for idx, threat in enumerate(state.get("external_threats", [])):
        path = f"external_threats[{idx}]"
        if not isinstance(threat, dict):
            errors.append(f"{path}: expected dict, got {type(threat).__name__}")
            continue
        _check_required(threat, {
            "id": str, "name": str,
            "threat_type": str, "region": str, "clock": dict,
        }, path, errors)
        tid = threat.get("id")
        if isinstance(tid, str):
            if tid in seen_threat_ids:
                errors.append(f"{path}.id: duplicate threat id '{tid}'")
            seen_threat_ids.add(tid)
        if isinstance(threat.get("clock"), dict):
            _validate_clock_shape(threat["clock"], f"{path}.clock", errors)
        status = threat.get("status")
        if isinstance(status, str) and status not in VALID_THREAT_STATUS:
            errors.append(f"{path}.status: '{status}' not in {VALID_THREAT_STATUS}")

    for idx, rel in enumerate(state.get("faction_relationships", [])):
        path = f"faction_relationships[{idx}]"
        if not isinstance(rel, dict):
            errors.append(f"{path}: expected dict, got {type(rel).__name__}")
            continue
        _check_required(rel, {
            "faction_a": str, "faction_b": str, "complication": str,
        }, path, errors)

    for list_name in ("clocks", "meta_clocks"):
        for idx, clock in enumerate(state.get(list_name, [])):
            path = f"{list_name}[{idx}]"
            if not isinstance(clock, dict):
                errors.append(f"{path}: expected dict, got {type(clock).__name__}")
                continue
            _validate_clock_shape(clock, path, errors)

    _validate_known_npcs(state.get("known_npcs", []), errors)
    _validate_known_locations(state.get("known_locations", []), errors)
    _validate_chronicle(state.get("chronicle", []), errors)
    _validate_clock_log(state.get("clock_log", []), errors)

    pulse = state.get("world_pulse", {})
    if isinstance(pulse, dict):
        _check_required(pulse, {
            "day": int, "news": str,
            "rumors": list, "trends": list, "arrivals": list,
        }, "world_pulse", errors)

    # --- Layer 3: Cross-reference integrity ---
    _validate_cross_references(state, errors)

    # --- Layer 4: Mechanical invariants ---
    _validate_clock_invariants(state, errors)

    # --- Layer 5: Sync checks ---
    _validate_sync(state, errors)

    return errors


# ---------------------------------------------------------------------------
# CLI entry point
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(description="Validate RPG Engine world-state JSON")
    parser.add_argument("state_json", help="Path to world state JSON file")
    args = parser.parse_args()

    path = Path(args.state_json)
    try:
        state = json.loads(path.read_text())
    except FileNotFoundError:
        print(f"ERROR: File not found: {path}", file=sys.stderr)
        return 2
    except json.JSONDecodeError as exc:
        print(f"ERROR: Invalid JSON in {path}: {exc}", file=sys.stderr)
        return 2

    errors = validate_state(state)
    if errors:
        print("World state validation FAILED:")
        for err in errors:
            print(f"- {err}")
        return 1

    print("World state validation PASSED")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
