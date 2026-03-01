# Execution Plan: Classify-Action Master Router + Enforcement

- **Owner:** Claude
- **Status:** Implemented (Rev 5 — master router doctrine)
- **Start Date:** 2026-02-21
- **Target Date:** 2026-02-21
- **Related:** `development/ongoing-plans/analysis/plan-cd-combined-implementations.md` (Implementation 3), `development/ongoing-plans/analysis/constraint-interpretation-drift-analysis.md`

---

## Objective

Establish `classify-action` as the **master router** for every gameplay turn. It runs first, determines which CLI commands are required, and the GM executes those commands. No gameplay turn proceeds without it. The only exception is explicit development mode (`DEVELOPMENT:` prefix). This doctrine is enshrined in the canonical rules, runtime governance, and enforced by a Stop hook.

---

## Design Decisions

| # | Decision | Rationale |
|---|---|---|
| D1 | Script lives in `phases/3-resolution/skills/core/scripts/` despite being a Phase 2 concern | All CLI-invoked Python follows the Phase 3 placement convention. Phase 2 skill invokes it via CLI subcommand, not direct import. |
| D2 | `scripts/CLAUDE.md` is an integration touchpoint, not a major surface | Per `change-integration-checklist.md` §3. Does not count toward surface limit. |
| D3 | Combat returns generic type, no subtype detection | State schema has no field for whose turn it is. 3 dedicated combat hooks already enforce subtypes. |
| D4 | No arena/stat/position suggestion in output | Duplicates `cli-selection.md` responsibility. Removed from output contract. |
| D5 | Escape hatch validates *type-appropriate* CLI, not *any* CLI | Scene-pressure + narrative resolution is the core drift pattern. Hook catches it specifically. |
| D6 | Compound actions produce `compound_action` boolean | Each sub-action needs its own `move` call. Enforcement is advisory — tracking across turns is out of scope. |
| D7 | **Strict CLI mandate:** no CLI = always block | A core CLI loop must always run during gameplay. The ONLY exception is `DEVELOPMENT:` prefix in the user message. |
| D8 | `--combat-active` flag removed | Derived from `scene_json.scene_type == "combat"`. One source of truth. |
| D9 | `--character-json` removed; `--scene-json` contract defined | Character data isn't needed for turn-type classification. Scene context requires `scene_type` and `threat_level`. |
| D10 | PRs are prerequisites in sequence, not independently valuable | PR 1 = testable code, PR 2 = doctrine wiring, PR 3 = enforcement. Land in rapid succession. |
| D11 | Test registered in `run_all_tests.py` OPTIONAL_MODULES | Without registration, test file never runs. |
| D12 | Hook fires first in Stop array | Phase 2 concern (classification) should be caught before Phase 3-5 hooks (narration, state). |
| D13 | `action-classification.md` remains; new skill supplements it | Existing skill is the advisory guide. New `mechanical-classification.md` documents the CLI ceremony. Both in routing table. |
| D14 | `post-cli-reminder.sh` NOT updated in this plan | Updating an existing hook adds surface (5) to PR 1. Stop hook catches missing CLI after the fact. Follow-up enhancement. |
| D15 | Sensory verbs in resolution regex are intentional | Only relevant for Path 3 (scene-pressure drift check). No-CLI paths block unconditionally. |
| D16 | **`classify-action` is the master router** | Runs first every gameplay turn. Determines which CLI commands are required. No turn proceeds without it. Doctrine enshrined in `hard-rules.md`, `runtime/CLAUDE.md`, `turn-loop.md`, `play-runbook.md`. |
| D17 | **`DEVELOPMENT:` prefix is the only escape** | User messages starting with `DEVELOPMENT:` bypass the master router entirely. This is the explicit development-mode signal. In-game OOC (`//`, `[meta]`) still goes through classify-action (returns `meta` type). |
| D18 | **OOC must go through classify-action** | `//` and `[meta]` are in-game OOC markers. The classifier returns `{turn_type: "meta", required_cli: []}`. The GM still runs classify-action; it just returns no required CLI. Only `DEVELOPMENT:` skips the router entirely. |
| D19 | 5 surfaces → 3 PRs | Adding `hard-rules.md` (Surface 2) and runtime governance wiring (Surface 4) requires a third PR. Each PR ≤ 2 surfaces. |
| D20 | PR 1 writes phase-manifest.md to final state (both cli_commands AND hooks) | Avoids PR 2 or PR 3 re-touching surface (6). Single edit, one PR owns the surface. |
| D21 | `DEVELOPMENT:` check is case-sensitive (all-caps only) | Deliberate signal, not casual text. Prevents false positives like "the development: of this area..." |

---

## Scope

**In scope:**
- New Python module `classify_action.py` — deterministic master router with 10 priority rules
- New `classify-action` CLI subcommand in `emergence_cli.py`
- New Phase 2 skill file `mechanical-classification.md`
- New Stop hook `enforce-classify-first.sh`
- **Doctrine wiring:** `hard-rules.md`, `runtime/CLAUDE.md`, `turn-loop.md`, `play-runbook.md`
- Integration touchpoints: script registry, Phase 2 index.md/CLAUDE.md, phase-manifest.md, test runner

**Out of scope:**
- Implementation 5 audit trail persistence (separate plan)
- Changes to existing hooks (validate-gm-response.sh, post-cli-reminder.sh remain as-is) [D14]
- State schema changes
- NLP libraries or external dependencies
- Combat subtype detection [D3]
- Arena/stat/position suggestion [D4]

---

## Surface Accounting

Per `change-integration-checklist.md` §3, 5 surfaces across 3 PRs (each PR ≤ 2):

| PR | Surfaces | Count | Key Files |
|---|---|---|---|
| 1 | (3) Phase scripts, (6) Phase manifest | 2 | `classify_action.py`, `emergence_cli.py`, test file, `run_all_tests.py`, `phase-manifest.md` |
| 2 | (2) Phase references, (4) Phase skills | 2 | `hard-rules.md`, `mechanical-classification.md`, Phase 2 CLAUDE.md/index.md, `scripts/CLAUDE.md` (touchpoint), runtime governance files (not a numbered surface) |
| 3 | (5) Validation/hooks | 1 | `enforce-classify-first.sh`, `.claude/settings.json` |

PR 1 writes `phase-manifest.md` to its final state (both `cli_commands` and `hooks`) so neither PR 2 nor PR 3 re-touches surface (6). [D20]

---

## Deliverables

### PR 1: Master Router Code + Tests (2 surfaces)

1. `classify_action.py` — Deterministic master router with 10 priority rules. Returns `{turn_type, required_cli, reasoning, is_ooc, compound_action}`. [D3, D4, D6]
2. `classify-action` subcommand registered in `emergence_cli.py`. [D8, D9]
3. `phase-manifest.md` updated with `cli_commands: classify-action` for Phase 2.
4. Unit tests passing — All 10 rules, priority ordering, compound detection, edge cases, input validation. [D11]

### PR 2: Doctrine Wiring + Skill (2 surfaces)

5. `hard-rules.md` updated — Rule 5 rewritten for master router doctrine, `DEVELOPMENT:` escape documented, Pre-Response Checklist updated. [D16, D17]
6. `mechanical-classification.md` created — Phase 2 skill documenting the classify-execute-narrate workflow. [D13]
7. Phase 2 `CLAUDE.md` + `index.md` updated — skill in routing table, hook enforcement section.
8. `runtime/CLAUDE.md` updated — GM Turn Pipeline, Seven Hard Rules summary.
9. `turn-loop.md` updated — Step 1 gains explicit classify-action step.
10. `play-runbook.md` updated — classify-action step in runtime interaction sequence.
11. `scripts/CLAUDE.md` updated — registry row for classify-action (touchpoint).
12. `phase-manifest.md` updated — `hooks: enforce-classify-first (Stop)` added to Phase 2. [D20]

### PR 3: Enforcement Hook (1 surface)

13. `enforce-classify-first.sh` — Stop hook enforcing the master router doctrine. [D5, D7]
14. Hook registered first in `.claude/settings.json` Stop array. [D12]

---

## PR 1 Tasks

### 1. Create `runtime/phases/3-resolution/skills/core/scripts/classify_action.py`

```python
def classify_action(player_message: str, scene_context: dict) -> dict:
    """Master router: classify player action into turn type with required CLI.

    Runs EVERY gameplay turn. Determines which CLI commands must execute.
    Only DEVELOPMENT: prefix bypasses this entirely (handled by caller/hook).

    Args:
        player_message: Player's declared action, verbatim.
        scene_context: Must contain 'scene_type' (str) and 'threat_level' (int).
                       Optional: 'location' (str), 'active_npcs' (str[]).

    Returns:
        {turn_type, required_cli, reasoning, is_ooc, compound_action}

    Raises:
        ValueError: If scene_context missing required fields.
    """
```

**Priority rules** (first match wins):

| # | Predicate | turn_type | required_cli |
|---|---|---|---|
| 0 | `DEVELOPMENT:` prefix | `development` | `[]`, `is_ooc: true` — explicit dev mode [D17] |
| 1 | `scene_type == "combat"` | `combat` | `[]` — combat hooks handle subtype [D3] |
| 2 | OOC markers: `//`, `OOC:`, `[meta]`, `[ooc]` | `meta` | `[]`, `is_ooc: true` [D18] |
| 3 | Session setup: `session-zero`, `character creation`, `new campaign` | `session_setup` | `["session-zero"]` |
| 4 | Downtime: `rest`, `sleep`, `train`, `craft`, `repair`, `build`, `gather info` | `downtime` | `["downtime"]` + `["move"]` if uncertain outcome |
| 5 | Travel: `go to`, `head to`, `travel`, `move to`, `leave`, `walk to`, `enter [location]` | `scene_transition` | `["world-tick", "clock-tick"]` |
| 6 | Action with stakes: `I try/attempt/want to/going to` + risk verb; `I [verb]` without certainty | `move_resolution` | `["move"]` |
| 7 | Social + NPC present: `talk to`, `ask`, `convince`, `persuade`, `threaten` + `active_npcs` non-empty | `social_interaction` | `["move"]` |
| 8 | Observation/safe: `look around`, `examine`, `check`, `what do I see`, `I wait`, `I observe` | `free_narration` | `["scene-pressure"]` |
| 9 | Fallback (no match) | `free_narration` | `["scene-pressure"]` |

**Implementation details:**
- Rules are an ordered list of `(predicate_fn, turn_type, required_cli)` tuples
- Rule 0 (`DEVELOPMENT:`) is checked first — before even combat. It short-circuits the entire router.
- Input validation: raise `ValueError` if `scene_type` or `threat_level` missing from scene_context
- Compound action detection: `and then`, `after that`, `once I`, `, then` → `compound_action: true` [D6]
- No arena/stat/position suggestion — classification only [D4]

### 2. Register `classify-action` subcommand in `emergence_cli.py`

- Add `p_classify_action = subparsers.add_parser("classify-action", help="Master router — classify player action into turn type")`
- Arguments: `--player-message` (required str), `--scene-json` (required JSON string)
- Handler: `cmd_classify_action(args)` — parse scene_json, call `classify_action()`, print JSON
- Add to `commands` dispatch dict

### 3. Update `runtime/phases/phase-manifest.md` (final state, both fields)

Phase 2 entry changes from:
```
- hooks: (none — advisory phase)
- cli_commands: (none — classification only)
```
to:
```
- hooks: enforce-classify-first (Stop)
- cli_commands: classify-action
```

Both fields written in PR 1 so no later PR re-touches surface (6). [D20]

### 4. Create `runtime/tests/test_classify_action.py`

- Follow existing test pattern: `ALL_TESTS` list of `(name, fn)` tuples, `run_test()` entry point
- Test Rule 0: `DEVELOPMENT:` prefix → `development` type, `is_ooc: true`
- Test each of rules 1-9 with representative input
- Test priority ordering: `DEVELOPMENT:` overrides everything, combat overrides OOC, OOC overrides action
- Test compound action detection: "I pick the lock and then sneak inside" → `compound_action: true`
- Test edge cases: empty message → fallback, mixed signals ("I try to rest")
- Test input validation: missing `scene_type` → `ValueError`
- Test combat returns empty `required_cli` [D3]

### 5. Register test in `runtime/tests/run_all_tests.py`

Add to `OPTIONAL_MODULES`: `("Classify-Action Rules", "test_classify_action")`

### 6. Run validators

- `python runtime/tests/run_all_tests.py 1`
- `python runtime/scripts/validate_docs_structure.py`
- `python runtime/scripts/validate_canonical_references.py`

---

## PR 2 Tasks

### 1. Update `runtime/phases/1-context-loading/references/hard-rules.md`

**Rule 5 rewrite.** Current text (line 56):
```
5. **EXECUTE `scene-pressure`** on EVERY free narration turn (no roll triggered) — NEVER narrate a turn without mechanical output
```

New text:
```
5. **EXECUTE `classify-action` FIRST** on EVERY gameplay turn — it is the master router that determines which CLI commands are required. THEN execute those commands. No turn proceeds without the router. The ONLY exception is prompts prefixed with `DEVELOPMENT:` (explicit development mode). In-game OOC (`//`, `[meta]`) still goes through the router — it returns `meta` type with no required CLI.
```

**Reference freshness:** Update the "Last verified against code commit" header to the HEAD commit hash after this PR lands.

**Pre-Response Checklist update.** Add as the FIRST item under "CLI Execution (CRITICAL)" (before line 265):
```
- [ ] Did I run `classify-action` with the player's message FIRST? (Master router — mandatory every turn)
- [ ] Did I execute ALL commands from its `required_cli` output?
```

**Common Failure Modes table update.** Add row:
```
| **Skipping Master Router** | Run `classify-action` FIRST every turn. It determines what CLI to run. Even "I look around" needs it. |
```

### 2. Update `runtime/CLAUDE.md`

**GM Turn Pipeline table** — Phase 2 row changes from:
```
| 2. Action Interpretation | `phases/2-action-interpretation/` | Classify action, select CLI command | Advisory only |
```
to:
```
| 2. Action Interpretation | `phases/2-action-interpretation/` | **Run `classify-action` master router**, select CLI command | enforce-classify-first (Stop) |
```

**Seven Hard Rules summary** — Rule 3 (line 41) changes from:
```
3. Roll 2d6 when the outcome is uncertain — use the CLI.
```
to:
```
3. Run `classify-action` first every turn — it determines which CLI commands to execute. `DEVELOPMENT:` prefix is the only exception.
```

### 3. Update `runtime/turn-loop.md`

**Step 1** changes from:
```
1. **Capture turn input (scene-only phase)**
   - Record player intent and identify which `emergence-cli` subcommand(s) are required.
```
to:
```
1. **Capture turn input and route via master router**
   - Record player intent verbatim.
   - If player message starts with `DEVELOPMENT:`, skip to development mode — no CLI required.
   - Otherwise, run `emergence_cli.py classify-action --player-message "<verbatim>" --scene-json '<scene>'`.
   - The router's `required_cli` output determines which subcommand(s) to execute in step 4.
```

### 4. Update `runtime/play-runbook.md`

**Two-phase runtime interaction** — insert between steps 2 and 3:
```
2b. **Route via master router**: `python scripts/emergence_cli.py classify-action --player-message "<action>" --scene-json '<context>'`
    - If `DEVELOPMENT:` prefix → skip to development mode.
    - Read `required_cli` from output. These are the commands to execute in step 4.
```

### 5. Create `runtime/phases/2-action-interpretation/skills/mechanical-classification.md`

- Summary: `classify-action` is the **master router** — runs first every gameplay turn, determines required CLI
- Prerequisites: player has declared action, context loading complete
- Steps:
  1. Check for `DEVELOPMENT:` prefix → if present, skip router entirely
  2. Run `classify-action` with player message + scene context
  3. Read JSON output for `turn_type` and `required_cli`
  4. If `compound_action` is true, resolve first action only, re-prompt player
  5. Execute ALL `required_cli` commands — no substitutions
  6. If `turn_type` is `combat`, follow combat hooks (no required_cli from classifier)
- Placement note: Python module lives in Phase 3 `core/scripts/` per CLI convention [D1]
- Reference: `action-classification.md` (advisory guide, still used for understanding) [D13]
- Reference: `hard-rules.md` §Rule 5 (master router mandate)
- Hooks That Enforce This: `enforce-classify-first.sh` (Stop)
- Common failures: skipping classify-action, ignoring required_cli, using `//` to avoid the router (doesn't work — OOC still routes through it), assuming "no stakes" when outcome is uncertain

### 6. Update Phase 2 integration touchpoints

- `runtime/phases/2-action-interpretation/index.md` — Add `mechanical-classification.md` row to skills table
- `runtime/phases/2-action-interpretation/CLAUDE.md` — Add skill to routing table, replace "No Hook Enforcement" with:
  ```
  ## Hook Enforcement
  - `enforce-classify-first.sh` (Stop) — Enforces the master router doctrine. Blocks any
    gameplay turn where no CLI ran. Only `DEVELOPMENT:` prefix bypasses enforcement.
  ```
- `runtime/scripts/CLAUDE.md` — Add `classify-action` row: "Master router — classify player action into turn type | Yes"

### 7. Run validators

- `python runtime/tests/run_all_tests.py 1`
- `python runtime/scripts/validate_docs_structure.py`
- `python runtime/scripts/validate_canonical_references.py`
- `python runtime/scripts/validate_reference_freshness.py` (hard-rules.md was modified)

---

## PR 3 Tasks

### 1. Create `.claude/hooks/enforce-classify-first.sh`

The hook has 5 sections.

#### Section A: Standard preamble

```bash
#!/bin/bash
# =============================================================================
# EMERGENCE RPG — Stop Hook: Enforce Master Router (classify-action)
# =============================================================================
# Every gameplay turn must run a core CLI command. The master router
# (classify-action) determines which. Only DEVELOPMENT: prefix in the
# user message bypasses this requirement.
#
# Hook event: Stop
# Exit 0 + JSON {decision: "block", reason: "..."} = force retry
# Exit 0 + no output = allow
# =============================================================================

INPUT=$(cat)

STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
    exit 0
fi

TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty')
if [ -z "$TRANSCRIPT_PATH" ] || [ ! -f "$TRANSCRIPT_PATH" ]; then
    exit 0
fi

PROJECT_DIR=$(echo "$INPUT" | jq -r '.cwd // empty')
if [ -z "$PROJECT_DIR" ]; then
    exit 0
fi

# ---- RPG session detection ----
CAMPAIGN_DIR="$PROJECT_DIR/runtime/campaigns"
ALT_CAMPAIGN_DIR="$PROJECT_DIR/campaigns"

IN_RPG_SESSION=false
if [ -d "$CAMPAIGN_DIR" ] || [ -d "$ALT_CAMPAIGN_DIR" ]; then
    TAIL_CONTENT=$(tail -20 "$TRANSCRIPT_PATH" 2>/dev/null || echo "")
    if echo "$TAIL_CONTENT" | grep -qi \
        "emergence\|what do you do\|emergence_cli\|state\.json\|world pulse\|clock-tick\|combat.*round\|HP:.*Stamina\|session.zero\|Vaelithar"; then
        IN_RPG_SESSION=true
    fi
fi

if [ "$IN_RPG_SESSION" = false ]; then
    exit 0
fi
```

#### Section B: Exception paths

```bash
# ---- Exception 1: DEVELOPMENT: prefix in user message ----
# This is the ONLY way to bypass the master router. [D17]
LAST_USER=$(tac "$TRANSCRIPT_PATH" 2>/dev/null | while IFS= read -r line; do
    ROLE=$(echo "$line" | jq -r '.role // empty' 2>/dev/null)
    if [ "$ROLE" = "user" ]; then
        echo "$line" | jq -r '.content // empty' 2>/dev/null
        break
    fi
done)

if echo "$LAST_USER" | grep -qE "^\s*DEVELOPMENT:"; then
    exit 0  # Explicit development mode — no CLI required [D21]
fi

# ---- Exception 2: No state file → pre-session-zero ----
STATE_FILE=""
if [ -d "$PROJECT_DIR/campaigns" ]; then
    STATE_FILE=$(find "$PROJECT_DIR/campaigns" -name "state.json" -maxdepth 2 2>/dev/null | head -1)
fi
if [ -z "$STATE_FILE" ] && [ -d "$PROJECT_DIR/runtime/campaigns" ]; then
    STATE_FILE=$(find "$PROJECT_DIR/runtime/campaigns" -name "state.json" -maxdepth 2 2>/dev/null | head -1)
fi

if [ -z "$STATE_FILE" ]; then
    exit 0
fi

# ---- Exception 3: Combat active → handled by dedicated combat hooks ----
if [ -f "$STATE_FILE" ]; then
    COMBAT_ACTIVE=$(cat "$STATE_FILE" | jq -r '.current_scene.combat_state.active // false' 2>/dev/null)
    if [ "$COMBAT_ACTIVE" = "true" ]; then
        exit 0
    fi
fi

# ---- Exception 4: Session setup (multi-turn session-zero conversation) ----
# classify-action was called at the START of session-zero. These are follow-up
# turns within the session-zero flow (character creation, aspect selection, etc.)
# where the GM is iterating with the player. Not a new gameplay turn.
LAST_ASSISTANT=$(tac "$TRANSCRIPT_PATH" 2>/dev/null | while IFS= read -r line; do
    ROLE=$(echo "$line" | jq -r '.role // empty' 2>/dev/null)
    if [ "$ROLE" = "assistant" ]; then
        echo "$line" | jq -r '.content // empty' 2>/dev/null
        break
    fi
done)

if echo "$LAST_ASSISTANT" | grep -qiE \
    "campaign name|session zero|choose.*aspect|choose.*archetype|select.*form|which campaign|character concept|what.*class|new campaign"; then
    exit 0
fi
```

#### Section C: CLI call detection

```bash
RECENT_TRANSCRIPT=$(tail -50 "$TRANSCRIPT_PATH" 2>/dev/null || echo "")

CLASSIFY_CALLED=false
if echo "$RECENT_TRANSCRIPT" | grep -q "classify-action"; then
    CLASSIFY_CALLED=true
fi

HIGH_VALUE_CLI=false
if echo "$RECENT_TRANSCRIPT" | grep -qE "emergence_cli.py (move|attack|evaluate-behavior) "; then
    HIGH_VALUE_CLI=true
fi

SCENE_PRESSURE_ONLY=false
if echo "$RECENT_TRANSCRIPT" | grep -q "scene-pressure"; then
    if ! echo "$RECENT_TRANSCRIPT" | grep -qE \
        "emergence_cli.py (move|attack|evaluate-behavior|classify-action) "; then
        SCENE_PRESSURE_ONLY=true
    fi
fi

ANY_CLI=false
if echo "$RECENT_TRANSCRIPT" | grep -q "emergence_cli"; then
    ANY_CLI=true
fi
```

#### Section D: Narrative resolution detection (for Path 3 only)

```bash
RESOLVES_ACTION=false

# Pattern 1: "you [resolution verb]"
if echo "$LAST_ASSISTANT" | grep -qiE \
    "you (succeed|manage|fail|stumble|slip|sneak past|convince|find|discover|dodge|block|land a|hit|miss|struggle|push through|climb|jump|break|pick|grab|escape|avoid|resist|overcome|reach|cross|enter|open|unlock|solve|figure out|notice|spot|detect|sense|hear|smell|read|decipher|craft|build|repair|heal|negotiate|barter|persuade|deceive|intimidate|charm|calm|rally|provoke|disarm|outrun|outmaneuver|overpower|outsmart)"; then
    RESOLVES_ACTION=true
fi

# Pattern 2: Environmental resolution
if echo "$LAST_ASSISTANT" | grep -qiE \
    "the (lock|door|wall|barrier|trap|puzzle|mechanism|device|gate|chest|container|rope|chain|window|hatch|grate|panel) (opens|breaks|yields|gives way|activates|disarms|clicks|releases|snaps|crumbles|shatters|slides|swings)"; then
    RESOLVES_ACTION=true
fi

# Pattern 3: Effort-framed resolution
if echo "$LAST_ASSISTANT" | grep -qiE \
    "(with (a|great|considerable) (effort|strain|grunt|heave)|after (a|some|several) (moment|attempt|tries?|seconds?))[^.]*you"; then
    RESOLVES_ACTION=true
fi
```

#### Section E: Decision tree

**Core principle [D7, D16, D17]:** The master router runs every gameplay turn. `DEVELOPMENT:` is the only escape (checked in Section B). If we reach this point, a CLI must have run.

```bash
# Path 1: classify-action was called → ALLOW (master router ran)
if [ "$CLASSIFY_CALLED" = true ]; then exit 0; fi

# Path 2: High-value CLI ran (move/attack/evaluate-behavior) → ALLOW
if [ "$HIGH_VALUE_CLI" = true ]; then exit 0; fi

# Path 3: Only scene-pressure ran → check for drift
if [ "$SCENE_PRESSURE_ONLY" = true ]; then
    if [ "$RESOLVES_ACTION" = true ]; then
        REASON="CLASSIFICATION DRIFT: You ran 'scene-pressure' but narrated an action
resolution with uncertain outcome. The master router (classify-action) must run first
every turn. Run 'emergence_cli.py classify-action' then execute its required_cli.
See: hard-rules.md §Rule 5, mechanical-classification.md"
        echo "{\"decision\": \"block\", \"reason\": $(echo "$REASON" | jq -Rs .)}"
        exit 0
    fi
    exit 0  # scene-pressure + no resolution = genuine free narration → ALLOW
fi

# Path 4: Other CLI ran (world-tick, creature, npc, etc.) → ALLOW
if [ "$ANY_CLI" = true ]; then exit 0; fi

# Path 5: NO CLI at all → BLOCK
# Not a DEVELOPMENT: turn (checked in Section B). A CLI must have run.
REASON="MASTER ROUTER VIOLATION: No CLI executed this turn. The master router
(classify-action) must run EVERY gameplay turn — it determines which CLI commands
are required. Even OOC questions (// or [meta]) go through the router.
Only 'DEVELOPMENT:' prefix bypasses this requirement.
Run: emergence_cli.py classify-action --player-message '<message>' --scene-json '<context>'
See: hard-rules.md §Rule 5"
echo "{\"decision\": \"block\", \"reason\": $(echo "$REASON" | jq -Rs .)}"
exit 0
```

**Decision tree summary:**

| Path | Condition | Result |
|---|---|---|
| — | `DEVELOPMENT:` prefix (Section B) | ALLOW (only escape) |
| 1 | classify-action called | ALLOW |
| 2 | move/attack/evaluate-behavior ran | ALLOW |
| 3a | scene-pressure only + resolves action | **BLOCK** (drift) |
| 3b | scene-pressure only + no resolution | ALLOW |
| 4 | other CLI ran | ALLOW |
| 5 | no CLI at all | **BLOCK** |

### 2. Register hook in `.claude/settings.json`

Insert as **first** entry in `hooks.Stop[0].hooks` array, before `validate-gm-response.sh`. [D12]

**New Stop hooks order:**
```
1. enforce-classify-first.sh       ← NEW (master router enforcement)
2. validate-gm-response.sh
3. validate-combat-state.sh
4. validate-combat-round-lifecycle.sh
5. validate-enemy-behavior.sh
6. validate-forced-consequence.sh
7. validate-narrative-principles.sh
8. enforce-state-save.sh
```

### 3. Manual integration tests (8 scenarios)

| # | Setup | Expected | Reason |
|---|---|---|---|
| T1 | classify-action called, then move | ALLOW | Happy path — master router ran |
| T2 | move called without classify-action | ALLOW | High-value escape hatch [D5] |
| T3 | Only scene-pressure, response resolves action | **BLOCK** | Drift pattern |
| T4 | Only scene-pressure, atmospheric response | ALLOW | Free narration (CLI ran) |
| T5 | No CLI, response resolves action | **BLOCK** | No CLI ran [D7] |
| T6 | No CLI, response is scene-setting | **BLOCK** | No CLI ran — must run router [D16] |
| T7 | No CLI, response has `//` OOC content | **BLOCK** | OOC must go through router [D18] |
| T8 | User message starts with `DEVELOPMENT:` | ALLOW | Only escape [D17] |

---

## Doctrine Placement Summary

The master-router doctrine is enshrined in these locations, organized by authority:

| Authority level | File | What changes |
|---|---|---|
| 1. Canonical rule | `hard-rules.md` §Rule 5 | Master router mandate + `DEVELOPMENT:` escape |
| 2. Operational governance | `runtime/CLAUDE.md` §Pipeline, §Rules | Phase 2 becomes "Run master router", Rule 3 updated |
| 3. Turn contract | `turn-loop.md` §Step 1 | "Route via master router" replaces "identify subcommands" |
| 4. Operational runbook | `play-runbook.md` §Step 2b | New step between capture and resolve |
| 5. Phase skill | `mechanical-classification.md` | Detailed workflow for the classify-execute-narrate cycle |
| 6. Phase routing | Phase 2 `CLAUDE.md` | Skill + hook enforcement section |
| 7. System config | `phase-manifest.md` | `cli_commands: classify-action`, `hooks: enforce-classify-first` |
| 8. Script registry | `scripts/CLAUDE.md` | New row for classify-action |
| 9. Enforcement | `enforce-classify-first.sh` + `settings.json` | Stop hook, first in chain |

Every runtime entry point that a GM encounters during play references the doctrine. A GM cannot start a turn without encountering "run classify-action first."

---

## Hook Interaction Model

**How Stop hooks execute:** All 8 hooks fire sequentially. If any blocks, the agent retries. On retry, `stop_hook_active = true` → all hooks exit immediately. Next normal stop, hooks fire fresh.

**Key difference from Rev 4:** The OOC check (`//`, `[meta]` in the response) is **removed** from the hook. In-game OOC must go through classify-action [D18]. Only `DEVELOPMENT:` in the user message bypasses enforcement. This means:
- Player says `// what level am I?` → GM must run `classify-action` → gets `meta` type → no further CLI needed → hook sees classify-action was called → ALLOW
- Player says `DEVELOPMENT: fix the creature table` → hook checks user message, sees `DEVELOPMENT:` → ALLOW without any CLI

**Overlap with validate-gm-response.sh:** The new hook is strictly stronger for no-CLI cases. It fires first and forces CLI execution. After correction, existing hooks have nothing to catch. No modifications to existing hooks needed.

---

## Validation Checklist

```
PR 1:
- [ ] python runtime/tests/run_all_tests.py 1
- [ ] python runtime/scripts/validate_docs_structure.py
- [ ] python runtime/scripts/validate_canonical_references.py
- [ ] Manual: classify-action "DEVELOPMENT: fix bug" → development, is_ooc: true [D17]
- [ ] Manual: classify-action "I try to pick the lock" + exploration → move_resolution, ["move"]
- [ ] Manual: classify-action "I look around" + exploration → free_narration, ["scene-pressure"]
- [ ] Manual: classify-action "// what level am I?" → meta, is_ooc: true [D18]
- [ ] Manual: classify-action "I attack the guard" + combat → combat, [] [D3]
- [ ] Manual: classify-action "I pick the lock and then sneak" → compound_action: true [D6]

PR 2:
- [ ] python runtime/scripts/validate_reference_freshness.py (hard-rules.md modified)
- [ ] python runtime/scripts/validate_docs_structure.py
- [ ] python runtime/scripts/validate_canonical_references.py
- [ ] Phase 2 CLAUDE.md under 40 lines (repo-maintenance-policy §1.4)
- [ ] hard-rules.md "Last verified" commit hash updated
- [ ] turn-loop.md step 1 references classify-action
- [ ] play-runbook.md has classify-action step
- [ ] runtime/CLAUDE.md pipeline table updated

PR 3:
- [ ] T1-T8 manual integration tests (see table above)
- [ ] T8 specifically: DEVELOPMENT: prefix allows no-CLI turn

All:
- [ ] All pre-existing validators still pass
```

---

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| Regex classifier misclassifies ambiguous messages | Fallback → `free_narration` with `scene-pressure`. Safest default. |
| Mandatory CLI call adds per-turn latency | Pure Python, no I/O. <100ms. |
| 8th Stop hook creates block-fix-block cycles | Narrow scope: only checks if CLI ran. Trusts existing hooks for downstream. [D12] |
| Resolution regex false positives in Path 3 | Only matters for scene-pressure drift. No-CLI paths block unconditionally. Regex can be tuned. |
| `compound_action` is advisory, not enforced | Known limitation. Tracking across turns is out of scope. [D6] |
| `post-cli-reminder.sh` has no classify-action branch | Known gap. Follow-up enhancement. [D14] |
| 3-PR sequence creates merge ordering risk | PRs touch disjoint surfaces. Land in rapid succession. Each is independently non-breaking. |
| Doctrine wiring across 9 locations creates maintenance burden | All locations reference `hard-rules.md` §Rule 5 as the canonical source. Updates flow from one place. |

---

## Exit Criteria

1. `classify-action` CLI returns correct JSON for all 10 priority rules including `DEVELOPMENT:`. [D17]
2. Output is `{turn_type, required_cli, reasoning, is_ooc, compound_action}`. [D4, D6]
3. All unit tests pass, registered in `run_all_tests.py`. [D11]
4. (PR 2) `hard-rules.md` §Rule 5 documents master router mandate and `DEVELOPMENT:` escape.
5. (PR 2) `runtime/CLAUDE.md`, `turn-loop.md`, `play-runbook.md` all reference classify-action as mandatory first step.
6. (PR 2) Phase 2 skill, index, CLAUDE.md, phase-manifest, and script registry all updated.
7. (PR 3) Hook blocks ANY gameplay turn with no CLI. [D7]
8. (PR 3) Hook blocks scene-pressure-only turns that resolve uncertain-outcome actions. [D5]
9. (PR 3) Hook allows `DEVELOPMENT:` prefix turns without any CLI. [D17]
10. (PR 3) Hook allows turns where classify-action was skipped but high-value CLI ran. [D5]
11. All existing validators pass.

---

## Appendix A: Input Contract

**`--player-message`** (required string): Player's declared action, verbatim. May include `DEVELOPMENT:` prefix.

**`--scene-json`** (required JSON string): Current scene context.

| Field | Type | Required | Source |
|---|---|---|---|
| `scene_type` | string enum | Yes | `state.json → current_scene.scene_type` |
| `threat_level` | integer 0-10 | Yes | `state.json → current_scene.threat_level` |
| `location` | string | No | `state.json → current_scene.location` |
| `active_npcs` | string[] | No | NPC names present in scene |

## Appendix B: Output Contract

```json
{
  "turn_type": "move_resolution",
  "required_cli": ["move"],
  "reasoning": "Player declared 'I try to pick the lock' — uncertain outcome with stakes.",
  "is_ooc": false,
  "compound_action": false
}
```

`turn_type` values: `development`, `combat`, `meta`, `session_setup`, `downtime`, `scene_transition`, `move_resolution`, `social_interaction`, `free_narration`

## Appendix C: File Inventory

| Action | File | PR | Surface |
|---|---|---|---|
| CREATE | `runtime/phases/3-resolution/skills/core/scripts/classify_action.py` | 1 | (3) |
| CREATE | `runtime/tests/test_classify_action.py` | 1 | — |
| CREATE | `runtime/phases/2-action-interpretation/skills/mechanical-classification.md` | 2 | (4) |
| CREATE | `.claude/hooks/enforce-classify-first.sh` | 3 | (5) |
| MODIFY | `runtime/scripts/emergence_cli.py` | 1 | (3) |
| MODIFY | `runtime/phases/phase-manifest.md` | 1 | (6) |
| MODIFY | `runtime/tests/run_all_tests.py` | 1 | — |
| MODIFY | `runtime/phases/1-context-loading/references/hard-rules.md` | 2 | (2) |
| MODIFY | `runtime/CLAUDE.md` | 2 | governance |
| MODIFY | `runtime/turn-loop.md` | 2 | governance |
| MODIFY | `runtime/play-runbook.md` | 2 | governance |
| MODIFY | `runtime/phases/2-action-interpretation/index.md` | 2 | (4) |
| MODIFY | `runtime/phases/2-action-interpretation/CLAUDE.md` | 2 | (4) |
| MODIFY | `runtime/scripts/CLAUDE.md` | 2 | touchpoint |
| MODIFY | `.claude/settings.json` | 3 | (5) |
