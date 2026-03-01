"""
Test suite for deep state validation (validate_state.py).

Covers:
  - Layer 1: Top-level structure (required keys, forbidden keys, types)
  - Layer 2: Domain-specific structure (character, factions, clocks, NPCs, etc.)
  - Layer 3: Cross-reference integrity (faction IDs, NPC IDs)
  - Layer 4: Mechanical invariants (clock consistency, resource pools)
  - Layer 5: Sync checks (duplicated fields must agree)

Uses the live state.json as the baseline "known-good" state, then injects
targeted mutations to verify each check fires.
"""

import copy
import json
import os
import sys

# Ensure validate_state is importable
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'scripts'))

from validate_state import validate_state


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

_STATE_PATH = os.path.join(
    os.path.dirname(os.path.abspath(__file__)), '..', 'state.json'
)


def _load_state():
    with open(_STATE_PATH) as f:
        return json.load(f)


def _mutate(state, path_parts, value):
    """Return a deep copy of *state* with the nested path set to *value*.

    path_parts is a list like ["character", "hp", "current"].
    If value is the sentinel _DELETE, the key is removed instead.
    """
    s = copy.deepcopy(state)
    obj = s
    for part in path_parts[:-1]:
        if isinstance(part, int):
            obj = obj[part]
        else:
            obj = obj[part]
    last = path_parts[-1]
    if value is _DELETE:
        if isinstance(last, int):
            del obj[last]
        else:
            obj.pop(last, None)
    else:
        obj[last] = value
    return s


class _DeleteSentinel:
    pass


_DELETE = _DeleteSentinel()


def _errors_containing(errors, substring):
    return [e for e in errors if substring in e]


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

def test_live_state_passes():
    """The committed state.json must pass all validation layers."""
    state = _load_state()
    errors = validate_state(state)
    if errors:
        print("UNEXPECTED validation errors on live state.json:")
        for e in errors:
            print(f"  - {e}")
    return len(errors) == 0


def test_forbidden_key_rejected():
    """Obsolete top-level keys must be rejected."""
    state = _load_state()
    state["entropy"] = 42
    errors = validate_state(state)
    return len(_errors_containing(errors, "entropy")) > 0


def test_missing_top_level_key():
    """Removing a required key must produce an error."""
    state = _load_state()
    del state["chronicle"]
    errors = validate_state(state)
    return len(_errors_containing(errors, "chronicle")) > 0


def test_wrong_type_top_level():
    """Wrong type for a required key must produce an error."""
    state = _load_state()
    state["current_day"] = "two"
    errors = validate_state(state)
    return len(_errors_containing(errors, "current_day")) > 0


# --- Layer 2: Character ---

def test_character_missing_field():
    state = _mutate(_load_state(), ["character", "hp"], _DELETE)
    errors = validate_state(state)
    return len(_errors_containing(errors, "character.hp")) > 0


def test_character_hp_overflow():
    """HP current > max must be caught."""
    state = _mutate(_load_state(), ["character", "hp", "current"], 999)
    errors = validate_state(state)
    return len(_errors_containing(errors, "character.hp")) > 0


def test_character_negative_stamina():
    state = _mutate(_load_state(), ["character", "stamina", "current"], -5)
    errors = validate_state(state)
    return len(_errors_containing(errors, "character.stamina.current")) > 0


def test_character_attribute_out_of_range():
    state = _mutate(_load_state(), ["character", "attributes", "might"], 0)
    errors = validate_state(state)
    return len(_errors_containing(errors, "character.attributes.might")) > 0


def test_character_attribute_too_high():
    state = _mutate(_load_state(), ["character", "attributes", "agility"], 31)
    errors = validate_state(state)
    return len(_errors_containing(errors, "character.attributes.agility")) > 0


def test_character_missing_attribute():
    state = _load_state()
    del state["character"]["attributes"]["willpower"]
    errors = validate_state(state)
    return len(_errors_containing(errors, "character.attributes.willpower")) > 0


def test_character_invalid_stance():
    state = _mutate(_load_state(), ["character", "combat", "current_stance"], "berserk")
    errors = validate_state(state)
    return len(_errors_containing(errors, "current_stance")) > 0


def test_character_ap_overflow():
    state = _mutate(_load_state(), ["character", "combat", "ap", "current"], 99)
    errors = validate_state(state)
    return len(_errors_containing(errors, "character.combat.ap")) > 0


def test_character_level_out_of_range():
    state = _mutate(_load_state(), ["character", "level"], 25)
    errors = validate_state(state)
    return len(_errors_containing(errors, "character.level")) > 0


def test_character_negative_xp():
    state = _mutate(_load_state(), ["character", "xp", "current"], -10)
    errors = validate_state(state)
    return len(_errors_containing(errors, "character.xp.current")) > 0


def test_character_duplicate_form_slot():
    state = _load_state()
    if len(state["character"]["forms"]) < 2:
        return True  # Skip if fewer than 2 forms
    state["character"]["forms"][1]["slot"] = 1  # Same as forms[0]
    errors = validate_state(state)
    return len(_errors_containing(errors, "duplicate slot")) > 0


def test_character_combat_history_negative():
    state = _mutate(_load_state(), ["character", "combat_history", "damage_dealt"], -1)
    errors = validate_state(state)
    return len(_errors_containing(errors, "combat_history.damage_dealt")) > 0


# --- Layer 2: Clocks ---

def test_clock_current_exceeds_max():
    state = _load_state()
    state["clocks"].append({
        "name": "Test Clock", "current": 99, "max": 4,
        "status": "active", "history": [],
    })
    errors = validate_state(state)
    return len(_errors_containing(errors, "current exceeds max")) > 0 or \
           len(_errors_containing(errors, "clocks[")) > 0


def test_clock_negative_current():
    state = _load_state()
    state["clocks"].append({
        "name": "Test Clock", "current": -1, "max": 4,
        "status": "active", "history": [],
    })
    errors = validate_state(state)
    return len(_errors_containing(errors, "clocks[")) > 0


def test_clock_invalid_status():
    state = _load_state()
    state["clocks"].append({
        "name": "Test Clock", "current": 1, "max": 4,
        "status": "exploded", "history": [],
    })
    errors = validate_state(state)
    return len(_errors_containing(errors, "status")) > 0


# --- Layer 2: NPCs ---

def test_npc_invalid_status():
    state = _load_state()
    state["known_npcs"].append({
        "id": "npc_999", "name": "Test NPC", "faction": "none",
        "role": "test", "disposition": "neutral", "status": "zombified",
    })
    errors = validate_state(state)
    return len(_errors_containing(errors, "status")) > 0


def test_npc_trust_out_of_range():
    state = _load_state()
    state["known_npcs"].append({
        "id": "npc_998", "name": "Test NPC", "faction": "none",
        "role": "test", "disposition": "neutral", "status": "active",
        "trust": 15,
    })
    errors = validate_state(state)
    return len(_errors_containing(errors, "trust")) > 0


def test_npc_duplicate_id():
    state = _load_state()
    state["known_npcs"].append({
        "id": "npc_997", "name": "NPC A", "faction": "none",
        "role": "test", "disposition": "neutral", "status": "active",
    })
    state["known_npcs"].append({
        "id": "npc_997", "name": "NPC B", "faction": "none",
        "role": "test", "disposition": "neutral", "status": "active",
    })
    errors = validate_state(state)
    return len(_errors_containing(errors, "duplicate NPC id")) > 0


# --- Layer 2: Chronicle ---

def test_chronicle_invalid_significance():
    state = _load_state()
    state["chronicle"].append({
        "day": 1, "time": "12:00", "event": "Test",
        "significance": "epic", "tags": [],
    })
    errors = validate_state(state)
    return len(_errors_containing(errors, "significance")) > 0


# --- Layer 2: Scene ---

def test_scene_invalid_type():
    state = _mutate(_load_state(), ["current_scene", "scene_type"], "boss_fight")
    errors = validate_state(state)
    return len(_errors_containing(errors, "current_scene.scene_type")) > 0


def test_scene_threat_level_out_of_range():
    state = _mutate(_load_state(), ["current_scene", "threat_level"], 15)
    errors = validate_state(state)
    return len(_errors_containing(errors, "current_scene.threat_level")) > 0


# --- Layer 3: Cross-reference integrity ---

def test_pc_standing_references_nonexistent_faction():
    state = _load_state()
    state["pc_standing"].append({
        "faction_id": "faction_FAKE",
        "rank": "unknown",
        "disposition": "neutral",
        "reputation_events": [],
    })
    errors = validate_state(state)
    return len(_errors_containing(errors, "faction_FAKE")) > 0


def test_inter_group_relation_bad_reference():
    state = _load_state()
    state["inter_group_relations"].append({
        "faction_a": "faction_NONEXISTENT",
        "faction_b": "threat_NONEXISTENT",
        "relation_type": "enmity",
        "history": [],
    })
    errors = validate_state(state)
    found = _errors_containing(errors, "NONEXISTENT")
    return len(found) >= 2  # Both faction_a and faction_b flagged


# --- Layer 4: Mechanical invariants ---

def test_completed_clock_mismatched_current():
    """A clock with status=completed but current != max must error."""
    state = _load_state()
    state["clocks"].append({
        "id": "clock_test",
        "name": "Test Clock",
        "current": 2,
        "max": 4,
        "status": "completed",
        "history": [],
    })
    errors = validate_state(state)
    return len(_errors_containing(errors, "status is 'completed' but current")) > 0


# --- Layer 5: Sync checks ---

def test_sync_current_day_mismatch():
    state = _load_state()
    state["current_day"] = 5
    # campaign.current_day stays at original value
    errors = validate_state(state)
    return len(_errors_containing(errors, "sync: current_day")) > 0


def test_sync_current_time_mismatch():
    state = _load_state()
    state["current_time"] = "23:59"
    errors = validate_state(state)
    return len(_errors_containing(errors, "sync: current_time")) > 0


# --- Layer 2: Faction ---

def test_faction_duplicate_id():
    state = _load_state()
    state["human_factions"].append({
        "id": "faction_1", "name": "Faction A", "archetype": "test",
        "goal": "test", "clock": {"name": "C", "current": 0, "max": 4},
    })
    state["human_factions"].append({
        "id": "faction_1", "name": "Faction B", "archetype": "test",
        "goal": "test", "clock": {"name": "C", "current": 0, "max": 4},
    })
    errors = validate_state(state)
    return len(_errors_containing(errors, "duplicate faction id")) > 0


def test_faction_power_level_out_of_range():
    state = _load_state()
    state["human_factions"].append({
        "id": "faction_99", "name": "Test", "archetype": "test",
        "goal": "test", "power_level": 15,
        "clock": {"name": "C", "current": 0, "max": 4},
    })
    errors = validate_state(state)
    return len(_errors_containing(errors, "power_level")) > 0


def test_threat_invalid_status():
    state = _load_state()
    state["external_threats"].append({
        "id": "threat_99", "name": "Test", "threat_type": "test",
        "region": "test",
        "clock": {"name": "C", "current": 0, "max": 4},
        "status": "annihilated",
    })
    errors = validate_state(state)
    return len(_errors_containing(errors, "status")) > 0


# --- Unexpected keys ---

def test_unexpected_top_level_key():
    """Typos in top-level keys should be flagged."""
    state = _load_state()
    state["chornicle"] = []  # typo
    errors = validate_state(state)
    return len(_errors_containing(errors, "chornicle")) > 0


# --- Clock edge cases ---

def test_portent_unfired_below_current():
    """Portent at threshold <= current but fired=false must error."""
    state = _load_state()
    state["clocks"].append({
        "name": "Test", "current": 3, "max": 5,
        "history": [], "status": "active",
        "portents": [{"at": 2, "event": "x", "mechanical": "y", "fired": False}],
    })
    errors = validate_state(state)
    return len(_errors_containing(errors, "but fired is false")) > 0


# ---------------------------------------------------------------------------
# Runner (compatible with run_all_tests.py pattern)
# ---------------------------------------------------------------------------

ALL_TESTS = [
    ("Live state passes", test_live_state_passes),
    ("Forbidden key rejected", test_forbidden_key_rejected),
    ("Missing top-level key", test_missing_top_level_key),
    ("Wrong type top-level", test_wrong_type_top_level),
    ("Character missing field", test_character_missing_field),
    ("Character HP overflow", test_character_hp_overflow),
    ("Character negative stamina", test_character_negative_stamina),
    ("Character attribute out of range (low)", test_character_attribute_out_of_range),
    ("Character attribute out of range (high)", test_character_attribute_too_high),
    ("Character missing attribute", test_character_missing_attribute),
    ("Character invalid stance", test_character_invalid_stance),
    ("Character AP overflow", test_character_ap_overflow),
    ("Character level out of range", test_character_level_out_of_range),
    ("Character negative XP", test_character_negative_xp),
    ("Character duplicate form slot", test_character_duplicate_form_slot),
    ("Character combat history negative", test_character_combat_history_negative),
    ("Clock current exceeds max", test_clock_current_exceeds_max),
    ("Clock negative current", test_clock_negative_current),
    ("Clock invalid status", test_clock_invalid_status),
    ("NPC invalid status", test_npc_invalid_status),
    ("NPC trust out of range", test_npc_trust_out_of_range),
    ("NPC duplicate id", test_npc_duplicate_id),
    ("Chronicle invalid significance", test_chronicle_invalid_significance),
    ("Scene invalid type", test_scene_invalid_type),
    ("Scene threat level out of range", test_scene_threat_level_out_of_range),
    ("PC standing bad faction ref", test_pc_standing_references_nonexistent_faction),
    ("Inter-group relation bad ref", test_inter_group_relation_bad_reference),
    ("Completed clock current != max", test_completed_clock_mismatched_current),
    ("Sync: current_day mismatch", test_sync_current_day_mismatch),
    ("Sync: current_time mismatch", test_sync_current_time_mismatch),
    ("Faction duplicate id", test_faction_duplicate_id),
    ("Faction power level out of range", test_faction_power_level_out_of_range),
    ("Threat invalid status", test_threat_invalid_status),
    ("Unexpected top-level key", test_unexpected_top_level_key),
    ("Portent unfired below current", test_portent_unfired_below_current),
]


def run_test():
    """Entry point for run_all_tests.py. Returns True if all pass."""
    passed = 0
    failed = 0
    for name, fn in ALL_TESTS:
        try:
            result = fn()
            if result:
                passed += 1
                print(f"  [PASS] {name}")
            else:
                failed += 1
                print(f"  [FAIL] {name}")
        except Exception as e:
            failed += 1
            print(f"  [ERR]  {name}: {e}")

    print(f"\n  State schema tests: {passed} passed, {failed} failed")
    return failed == 0


if __name__ == "__main__":
    success = run_test()
    sys.exit(0 if success else 1)
