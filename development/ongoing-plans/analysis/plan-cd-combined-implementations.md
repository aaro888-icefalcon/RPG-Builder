# Analysis: Five Combined Plan C+D Implementations

- **Date:** 2026-02-21
- **Depends on:** `constraint-interpretation-drift-analysis.md`
- **Objective:** Design 5 distinct architectures for combining Plan C (Phase 2 classification enforcement) with Plan D (structured turn receipt with classification audit) into a single coherent implementation.

---

## Turn Structure Inventory

Before designing enforcement, we must catalog every possible turn type and what CLI commands each requires. This is the complete map of "what should happen" that any enforcement system must validate against.

### Complete Turn Type Taxonomy

| Turn Type | Required CLI Commands | Optional CLI Commands | Phase Context |
|---|---|---|---|
| **Move Resolution** | `move` | `clock-tick` (if meta-move fires) | Exploration, Social, Downtime |
| **Free Narration** | `scene-pressure` | `clock-tick`, `npc-agenda` | Exploration (no-roll turn) |
| **Scene Transition** | `world-tick`, `clock-tick` (1-2) | `scene`, `adventure` | Any phase boundary |
| **Combat: Player Turn** | `attack` or `move` | `turn-start` (if conditions) | Combat |
| **Combat: Enemy Turn** | `evaluate-behavior`, `attack` | `turn-start` (if conditions) | Combat |
| **Combat: Round End** | `round-end` | `loot` (if enemy dies) | Combat |
| **Combat: Init** | `creature` or `creatures` | `roll` (initiative) | Combat entry |
| **Social: NPC Interaction** | At least one of: `move`, `npc`, `relationship` | `npc-agenda`, `diplomacy`, `pc-standing` | Social |
| **Downtime: Activity** | `downtime`, `move` (if uncertain) | `relationship`, `world-tick` | Downtime |
| **Downtime: Rest** | (state write only) | `world-tick` | Downtime |
| **Character Management** | `character` | — | Setup |
| **Session Setup** | `session-zero` | `character`, `scene` | Campaign start |
| **Meta/OOC** | (none) | — | Out-of-character |

### CLI Subcommand Complete Registry

**28 CLI subcommands** available through `emergence_cli.py`:

| # | Subcommand | Domain | Required Turn Types |
|---|---|---|---|
| 1 | `move` | world-building | Move resolution, social conflict, downtime checks |
| 2 | `attack` | combat | Player attack, enemy attack |
| 3 | `roll` | core | Basic 2d6 tests, initiative |
| 4 | `turn-start` | core | Combat turn with active conditions |
| 5 | `round-end` | combat | Every combat round boundary |
| 6 | `evaluate-behavior` | combat | Every enemy turn |
| 7 | `creature` | combat | Single creature generation |
| 8 | `creatures` | combat | Encounter group generation |
| 9 | `scene` | exploration | New location entry |
| 10 | `scene-pressure` | exploration | Every free narration turn |
| 11 | `adventure` | exploration | Adventure hook generation |
| 12 | `npc` | social | Quick NPC generation |
| 13 | `awakened-npc` | social | Combat-capable NPC generation |
| 14 | `relationship` | social | NPC trust changes |
| 15 | `npc-agenda` | combat/social | NPC escalation check |
| 16 | `diplomacy` | social | Faction relation changes |
| 17 | `pc-standing` | social | PC rank/disposition changes |
| 18 | `session-zero` | social | Campaign initialization |
| 19 | `clock-tick` | world-building | Clock advancement |
| 20 | `world-tick` | world-building | Scene transitions, time passage |
| 21 | `downtime` | downtime | Downtime activity resolution |
| 22 | `character` | core | Character creation/leveling |
| 23 | `loot` | core | Post-combat loot roll |
| 24 | `move --list-arenas` | world-building | Reference (no enforcement) |
| 25 | `move --list-situations` | world-building | Reference (no enforcement) |
| 26 | `move --list-soft-moves` | world-building | Reference (no enforcement) |
| 27 | `move --list-hard-moves` | world-building | Reference (no enforcement) |
| 28 | `move --list-meta-moves` | world-building | Reference (no enforcement) |

### Enforcement Gap Map

Current hooks enforce some turn types but leave others unguarded:

| Turn Type | Currently Enforced? | By Which Hook | Gap |
|---|---|---|---|
| Move Resolution | Partial | `validate-gm-response.sh` (V1) | Weak regex; misses many phrasings |
| Free Narration | **No** | — | `scene-pressure` never checked |
| Scene Transition | Partial | `validate-gm-response.sh` (V3) | Only checks travel verbs |
| Combat: Player Turn | Yes | `validate-combat-state.sh` | — |
| Combat: Enemy Turn | Yes | `validate-enemy-behavior.sh` | — |
| Combat: Round End | Yes | `validate-combat-round-lifecycle.sh` | — |
| Social: NPC | **No** | — | No social turn enforcement |
| Downtime | **No** | — | No downtime enforcement |
| State Persistence | Yes | `enforce-state-save.sh` | — |
| Forced Consequences | Yes | `validate-forced-consequence.sh` | — |
| Narrative Tone | Yes | `validate-narrative-principles.sh` | — |

**Key gaps to fill:** Free narration, social turns, downtime turns, and the general "was ANY CLI called?" question.

---

## Implementation 1: CLI Ledger Hook + Completeness Validator

**Architecture:** PostToolUse hook accumulates a per-turn CLI call ledger. Stop hook reads the ledger, infers turn type, and validates completeness.

**Principle:** No explicit GM declaration required. The system observes what happened and flags what's missing.

### Mechanism

**New file: `.claude/hooks/track-cli-ledger.sh`** (PostToolUse hook)
- Fires after every Bash tool call
- If the command contains `emergence_cli`, extracts the subcommand name and appends it to a temp file: `/tmp/emergence_turn_ledger_$$.txt`
- Temp file accumulates all CLI calls for the current turn
- Non-CLI Bash calls are ignored

**New file: `.claude/hooks/validate-turn-completeness.sh`** (Stop hook)
- Fires when GM finishes responding
- Reads the CLI ledger temp file
- Infers turn type from the CLI calls present:
  - If `attack` or `evaluate-behavior` present → combat turn
  - If `move` present (no attack) → move resolution turn
  - If `scene-pressure` present → free narration turn (valid)
  - If `world-tick` present → scene transition turn
  - If `downtime` present → downtime turn
  - If `session-zero` or `character` present → setup turn
  - If **no CLI calls at all** → unclassified (potential violation)
- Cross-references against response content:
  - If response contains narrative resolution (>80 words of prose) but no CLI calls → **BLOCK**: "No CLI executed. Run at minimum `scene-pressure` for free narration or the appropriate action CLI."
  - If `move` was called but `scene-pressure` was also needed (multiple player actions) → warn
  - If scene transition detected in text but no `world-tick` → **BLOCK**
- Writes classification to a turn receipt fragment file: `/tmp/emergence_turn_receipt_$$.json`
  ```json
  {
    "turn_type": "move_resolution",
    "cli_commands_executed": ["move"],
    "scene_pressure_required": false,
    "scene_pressure_executed": false,
    "classification_source": "inferred_from_ledger",
    "violations": []
  }
  ```
- Cleans up ledger temp file

**Modified file: `.claude/hooks/enforce-state-save.sh`**
- After validating state save, reads the turn receipt fragment
- Injects it into the state.json `meta.last_turn_classification` field
- This provides the audit trail without schema changes (uses the existing `meta` object)

### Scope Assessment

| Surface | Touched? | Details |
|---|---|---|
| Validation/hooks | Yes | 2 new hooks + 1 modified hook |
| Phase skills | Yes | New `classification-enforcement.md` skill in Phase 2 |
| Phase manifest | Yes | Phase 2 gains hooks; Phase 6 gains new validator |
| State schema | **No** | Uses existing `meta` freeform object |
| Phase references | No | — |
| Output rendering | No | — |
| Documentation | Yes (minor) | Phase 2 CLAUDE.md updated |

**Surfaces touched: 3** (hooks, skills, manifest) — at scope limit, no phased PRs required.

### Turn Type Inference Rules (Detailed)

```
PRIORITY ORDER (first match wins):
1. session-zero in ledger           → SESSION_SETUP
2. character in ledger              → CHARACTER_MANAGEMENT
3. evaluate-behavior in ledger      → COMBAT_ENEMY_TURN
4. round-end in ledger              → COMBAT_ROUND_END
5. attack in ledger (no eval-beh)   → COMBAT_PLAYER_TURN
6. move in ledger                   → MOVE_RESOLUTION
7. scene-pressure in ledger         → FREE_NARRATION (valid)
8. world-tick in ledger             → SCENE_TRANSITION
9. downtime in ledger               → DOWNTIME
10. npc/relationship/diplomacy      → SOCIAL_INTERACTION
11. scene/creature/creatures        → ENCOUNTER_SETUP
12. loot in ledger                  → LOOT_RESOLUTION
13. (nothing in ledger)             → UNCLASSIFIED ← violation candidate
```

### Validation Rules

```
UNCLASSIFIED + response_word_count > 80        → BLOCK (no CLI executed)
UNCLASSIFIED + response_word_count <= 80        → ALLOW (meta/OOC response)
MOVE_RESOLUTION + forced_consequence in output  → CHECK forced-consequence hook
COMBAT_* + no turn-start + conditions_active    → BLOCK (handled by existing hook)
SCENE_TRANSITION + no clock-tick               → BLOCK (add clock-tick)
FREE_NARRATION + clock_ticks_in_output          → CHECK clock persistence
```

### Pros
- **Zero burden on the GM** — classification is fully automated
- No schema changes — uses existing `meta` freeform field
- Cleanest separation of concerns (PostToolUse observes, Stop validates)
- Ledger provides complete audit trail of every CLI call

### Cons
- Inference can be wrong if turn has unusual CLI call combinations
- PostToolUse temp file approach is fragile (process ID collisions, cleanup)
- Doesn't prevent the misclassification — only catches it after the fact
- The "80 words of prose" heuristic for detecting narrative resolution is imprecise

---

## Implementation 2: Pre-Classification Injection + Post-Validation Gate

**Architecture:** UserPromptSubmit hook analyzes the player's message and pre-classifies the expected turn type. This classification is injected into context. A Stop hook then validates that the GM's response matched the injected classification.

**Principle:** Tell the GM what to do BEFORE it responds, then verify it did it.

### Mechanism

**Modified file: `.claude/hooks/inject-state-context.sh`** (UserPromptSubmit hook)
- After injecting state data, adds a new section: `[TURN CLASSIFICATION GUIDANCE]`
- Analyzes the last user message to determine expected turn type:
  - If user message matches action verbs with uncertain outcomes → `EXPECTED: MOVE_RESOLUTION — run 'move' CLI`
  - If user message is purely conversational/observational → `EXPECTED: FREE_NARRATION — run 'scene-pressure' CLI`
  - If combat is active in state.json → `EXPECTED: COMBAT_TURN — run appropriate combat CLI`
  - If user message references rest/train/craft → `EXPECTED: DOWNTIME — run 'downtime' CLI`
  - If user message is OOC (starts with `//`, `OOC:`, `[meta]`) → `EXPECTED: META — no CLI required`
- Includes the specific CLI command the GM should run:
  ```
  [TURN CLASSIFICATION GUIDANCE]
  Detected turn type: MOVE_RESOLUTION
  Required CLI: move --stat-score [STAT] --position [POS] --effect [EFF] --arena [ARENA]
  Reminder: Do NOT narrate the outcome until the CLI has been executed.
  If this classification is wrong, run the correct CLI anyway — every non-meta turn needs at least one CLI call.
  ```

**New file: `.claude/hooks/validate-classification-match.sh`** (Stop hook)
- Reads the classification that was injected (from the transcript — the UserPromptSubmit output is in the conversation)
- Reads the actual CLI calls from the transcript (same approach as Implementation 1)
- Compares expected vs. actual:
  - If expected was MOVE_RESOLUTION but no `move` was called → **BLOCK**
  - If expected was FREE_NARRATION but no `scene-pressure` was called → **BLOCK**
  - If expected was COMBAT but no combat CLI was called → **BLOCK**
  - If expected was META and no CLI was called → **ALLOW**
- Writes turn classification to a structured block that the `enforce-state-save.sh` hook picks up for persistence

**New file: `phases/2-action-interpretation/skills/pre-classification.md`** (Skill file)
- Documents the pre-classification skill
- Lists the classification rules
- References: `gm-protocol.md` §When NOT to Roll, `hard-rules.md` §Script Execution
- Hooks That Enforce This: `inject-state-context.sh` (injection), `validate-classification-match.sh` (validation)

**Turn receipt extension:** After state save, the classification is persisted in `meta.turn_classifications[]`:
```json
{
  "turn_number": 14,
  "expected_type": "MOVE_RESOLUTION",
  "actual_type": "MOVE_RESOLUTION",
  "cli_commands": ["move"],
  "match": true,
  "timestamp": "2026-02-21T14:30:00Z"
}
```

### Pre-Classification Rules (Detailed)

```
INPUT ANALYSIS (from user message):

1. COMBAT ACTIVE (state.json combat_state.active = true)
   → COMBAT_TURN (always, regardless of message content)

2. OOC MARKERS: starts with //, OOC:, [meta], [ooc]
   → META

3. ACTION VERB PATTERNS (uncertain outcome):
   "I try|attempt|want to|going to" + risk verb
   → MOVE_RESOLUTION

4. DOWNTIME PATTERNS:
   "rest|sleep|train|craft|repair|build|gather info|investigate the"
   → DOWNTIME

5. SOCIAL PATTERNS (NPC present in scene):
   "talk to|ask|tell|convince|persuade|threaten|negotiate|trade with"
   → SOCIAL_INTERACTION (may need MOVE_RESOLUTION for contested social)

6. TRAVEL PATTERNS:
   "go to|head to|travel|move to|leave|walk to|enter"
   → SCENE_TRANSITION (needs world-tick + clock-tick)

7. OBSERVATION/SAFE ACTIONS:
   "look around|examine|check|what do I see|describe"
   → FREE_NARRATION (needs scene-pressure)

8. FALLBACK (no pattern matched):
   → FREE_NARRATION (needs scene-pressure)
   (Rationale: if we can't determine the type, scene-pressure is the safest default — it always applies to non-CLI turns, and if the GM determines a move IS needed, they'll run `move` anyway which satisfies the validator.)
```

### Scope Assessment

| Surface | Touched? | Details |
|---|---|---|
| Validation/hooks | Yes | 1 modified hook + 1 new hook |
| Phase skills | Yes | New `pre-classification.md` in Phase 2 |
| Phase manifest | Yes | Phase 2 gains hooks |
| State schema | **No** | Uses `meta` freeform field |

**Surfaces touched: 3** — at scope limit.

### Pros
- **Proactive** — guides the GM BEFORE it can drift, not just after
- Leverages the existing `inject-state-context.sh` hook (already runs every turn)
- Pre-classification acts as chain-of-thought prompting — improves classification accuracy
- Fallback to FREE_NARRATION ensures `scene-pressure` is never skipped

### Cons
- Pre-classification from user message analysis can be wrong (player intent is ambiguous)
- Adds ~200 tokens to every turn's context injection
- The GM may override the classification correctly but still get blocked by the validator
- Need an escape hatch for when pre-classification is wrong (the validator should check ACTUAL behavior, not just match expected)

### Escape Hatch Design
The validator should not blindly enforce the pre-classification. Instead:
1. If expected ≠ actual BUT actual has valid CLI calls → **ALLOW** (GM correctly reclassified)
2. If expected ≠ actual AND no CLI calls → **BLOCK** (GM skipped everything)
3. If expected = META AND actual has CLI calls → **ALLOW** (GM went above and beyond)

---

## Implementation 3: Classify-Action CLI Subcommand + Hook Bridge

**Architecture:** A new Python CLI subcommand `classify-action` that the GM must call as the FIRST CLI command every turn. It takes the player's message and context, outputs a classification with required CLI commands. A PostToolUse hook enforces that `classify-action` was called. A Stop hook validates the classification was honored.

**Principle:** Make classification itself a mechanical, deterministic operation — not a judgment call.

### Mechanism

**New file: `runtime/phases/3-resolution/skills/core/scripts/classify_action.py`**
```python
def classify_action(
    player_message: str,
    combat_active: bool,
    scene_context: dict,
    character_state: dict
) -> dict:
    """
    Deterministic action classifier.

    Returns:
      {
        "turn_type": "move_resolution|free_narration|combat_player|...",
        "required_cli": ["move", "clock-tick"],
        "suggested_arena": "violence",
        "suggested_stat": "might",
        "suggested_position": "risky",
        "reasoning": "Player declared attack against hostile creature...",
        "is_ooc": false
      }
    """
```

Classification logic:
1. If `combat_active` → return combat subtype based on initiative order
2. Pattern-match `player_message` against action verb taxonomy
3. Cross-reference with `scene_context` (threat level, active NPCs, location type)
4. If outcome is uncertain AND stakes exist → `move_resolution`
5. If outcome is certain OR purely observational → `free_narration`
6. Output includes the specific CLI commands the GM must run next

**New CLI subcommand:** `classify-action`
```bash
python3 emergence_cli.py classify-action \
  --player-message "I try to sneak past the guards" \
  --combat-active false \
  --scene-json '{"threat_level": 3, "location": "checkpoint"}' \
  --character-json '{"level": 3, "attributes": {"agility": 14}}'
```

**Output:**
```json
{
  "turn_type": "move_resolution",
  "required_cli": ["move"],
  "suggested_arena": "physical_striving",
  "suggested_stat": "agility",
  "suggested_stat_score": 14,
  "suggested_position": "risky",
  "suggested_effect": "standard",
  "reasoning": "Sneaking past guards has uncertain outcome with real stakes (detection → combat). AGI-based physical_striving in risky position.",
  "is_ooc": false,
  "scene_pressure_required": false
}
```

**New file: `.claude/hooks/enforce-classify-first.sh`** (Stop hook)
- Checks if `classify-action` was called this turn (in the transcript)
- If NOT called and response is >50 words → **BLOCK**: "You must run `classify-action` CLI before narrating. This determines the required CLI commands for this turn."
- If called, reads the classification output and checks that all `required_cli` commands were subsequently executed
- If any required CLI was skipped → **BLOCK** with specific missing command

**Modified file: `runtime/scripts/CLAUDE.md`**
- Add `classify-action` to the script registry with `runtime-safe: yes`

**New file: `phases/2-action-interpretation/skills/mechanical-classification.md`**
- Skill file documenting the classify-action workflow
- Steps: 1) Run classify-action, 2) Read output, 3) Execute required CLIs, 4) Narrate based on results

**Turn receipt extension:** The `classify-action` output is persisted as-is in the turn receipt.

### Scope Assessment

| Surface | Touched? | Details |
|---|---|---|
| Phase scripts | Yes | New `classify_action.py` in core |
| Validation/hooks | Yes | 1 new Stop hook |
| Phase skills | Yes | New skill in Phase 2 |
| Phase manifest | Yes | Phase 2 gains hook + CLI command |
| Script registry | Yes | New subcommand in CLAUDE.md |

**Surfaces touched: 4** — exceeds scope limit, requires phased PRs:
- **PR 1:** `classify_action.py` + script registry + Phase 2 skill (3 surfaces: scripts, skills, manifest)
- **PR 2:** Hook + settings.json update (1 surface: hooks)

### Classification Algorithm (Detailed)

```python
PRIORITY_RULES = [
    # Rule 1: Combat override
    (combat_active, "combat_turn", determine_combat_subtype),

    # Rule 2: OOC detection
    (is_ooc_message, "meta", []),

    # Rule 3: Session setup
    (is_setup_message, "session_setup", ["session-zero"]),

    # Rule 4: Downtime patterns
    (matches_downtime, "downtime", ["downtime", "move"]),

    # Rule 5: Travel/transition
    (matches_travel, "scene_transition", ["world-tick", "clock-tick"]),

    # Rule 6: Action with stakes
    (matches_action_with_stakes, "move_resolution", ["move"]),

    # Rule 7: Social with NPC present
    (matches_social_and_npc_present, "social", ["move"]),

    # Rule 8: Observation/safe action
    (matches_observation, "free_narration", ["scene-pressure"]),

    # Rule 9: Fallback
    (True, "free_narration", ["scene-pressure"]),
]
```

### Pros
- **Deterministic classification** — removes all subjective judgment from Phase 2
- Python-based → testable, debuggable, can be unit-tested in CI
- The classification itself is auditable (JSON output in turn receipt)
- Suggests specific parameters (arena, stat, position) reducing GM guesswork
- Can be refined over time as new patterns emerge

### Cons
- Highest implementation complexity — new Python module + CLI subcommand + hook + skill
- Exceeds 3-surface scope limit → requires 2 phased PRs
- Adds a mandatory CLI call to every turn (latency cost)
- The classifier itself may misclassify — but at least it's deterministic and fixable
- Player message NLP is inherently imperfect even in Python

---

## Implementation 4: Structured Turn Header Contract + Schema-Light Audit

**Architecture:** The GM must include a structured turn header block at the top of every response. A Stop hook parses the header, validates it against actual CLI calls, and persists it. No schema changes — audit data lives in the turn receipt file.

**Principle:** Force the GM to explicitly declare its intentions in a machine-readable format, creating both a classification commitment and an audit trail in a single mechanism.

### Mechanism

**Required turn header format** (top of every GM response):
```
<!-- TURN: type=move_resolution cli=move arena=violence position=risky effect=standard -->
```

Or for free narration:
```
<!-- TURN: type=free_narration cli=scene-pressure -->
```

Or for combat:
```
<!-- TURN: type=combat_player cli=attack,turn-start -->
```

Or for meta/OOC:
```
<!-- TURN: type=meta cli=none -->
```

The header is an HTML comment — invisible to the player in rendered markdown but machine-parseable by hooks.

**New file: `.claude/hooks/validate-turn-header.sh`** (Stop hook)
- Extracts the `<!-- TURN: ... -->` header from the response
- If header is missing and response is >50 words → **BLOCK**: "Missing turn header. Add `<!-- TURN: type=X cli=Y -->` at the top of your response."
- Parses the header fields: `type`, `cli`, and any optional fields
- Cross-references against actual CLI calls in the transcript:
  - All commands listed in `cli=` must appear in the transcript
  - If `type=free_narration` and `scene-pressure` not in transcript → **BLOCK**
  - If `type=move_resolution` and `move` not in transcript → **BLOCK**
  - If `type=meta` and no CLI calls → **ALLOW**
- If header declares `cli=none` but CLI calls exist → **ALLOW** (GM went above and beyond)
- Writes validated header + actual execution data to turn receipt fragment

**Modified file: `.claude/hooks/inject-state-context.sh`**
- Adds a reminder at the end of the state injection:
  ```
  TURN HEADER REQUIRED: Start your response with:
  <!-- TURN: type=[TYPE] cli=[COMMANDS] -->
  Types: move_resolution, free_narration, combat_player, combat_enemy,
         combat_round_end, scene_transition, social, downtime, meta
  ```

**New file: `phases/2-action-interpretation/skills/turn-header-declaration.md`**
- Skill file documenting the turn header contract
- Full list of valid types and their required CLI commands
- Common failure: omitting the header (caught by hook)

**Turn receipt persistence:** `enforce-state-save.sh` reads the turn receipt fragment and appends to a `turn_log.jsonl` file in the campaign directory:
```json
{"turn": 14, "type": "move_resolution", "declared_cli": ["move"], "actual_cli": ["move", "clock-tick"], "match": true, "timestamp": "2026-02-21T14:30:00Z"}
```

### Turn Header Validation Matrix

| Declared Type | Required in `cli=` | Validation |
|---|---|---|
| `move_resolution` | `move` | `move` must appear in transcript |
| `free_narration` | `scene-pressure` | `scene-pressure` must appear in transcript |
| `combat_player` | `attack` or `move` | At least one must appear |
| `combat_enemy` | `evaluate-behavior` | Must appear in transcript |
| `combat_round_end` | `round-end` | Must appear in transcript |
| `scene_transition` | `world-tick` | Must appear, `clock-tick` recommended |
| `social` | `move` or `npc` or `relationship` | At least one must appear |
| `downtime` | `downtime` | Must appear, `move` if uncertain outcome |
| `meta` | `none` | No CLI required |
| `session_setup` | `session-zero` or `character` | At least one must appear |

### Scope Assessment

| Surface | Touched? | Details |
|---|---|---|
| Validation/hooks | Yes | 1 new Stop hook, 1 modified hook |
| Phase skills | Yes | New skill in Phase 2 |
| Phase manifest | Yes | Phase 2 gains hook |
| State schema | **No** | Audit log is separate JSONL file |

**Surfaces touched: 3** — at scope limit.

### Pros
- **Explicit declaration** acts as chain-of-thought — the GM must think about classification before narrating
- HTML comment header is invisible to the player (clean UX)
- Machine-parseable — simple regex extraction in the hook
- Turn log JSONL file provides full session audit without schema changes
- No new Python code — pure bash hook implementation
- The GM can see the previous turn's header in conversation history, reinforcing the pattern

### Cons
- Relies on the GM remembering to include the header (mitigated by the block)
- HTML comment syntax is unusual — may confuse the model initially
- The header is advisory text that the model generates — it could hallucinate a header without actually running the CLI
- Need to handle edge cases: multiple turns per response, partial headers, malformed syntax
- The JSONL audit log is a new file artifact to manage

### Edge Case Handling
- **Multiple actions in one turn:** Header lists all: `cli=move,clock-tick,scene-pressure`
- **GM overrides classification:** If header says `free_narration` but GM ran `move` → **ALLOW** (more enforcement is fine)
- **Malformed header:** Treat as missing → **BLOCK**
- **Combat with no header:** Combat hooks already enforce combat turns — header is redundant but still required for audit completeness

---

## Implementation 5: Dual-Phase Validation with Inferred Classification + Persistent Audit Trail

**Architecture:** Combines the best of automatic inference (no GM burden) with persistent audit (turn receipt fields). A two-pass Stop hook system where Pass 1 infers classification from CLI calls, and Pass 2 validates completeness and persists the classification. Uses a lightweight state.json extension for the audit trail.

**Principle:** Infer, validate, persist — all automatically, with no additional GM effort.

### Mechanism

**New file: `.claude/hooks/classify-and-validate-turn.sh`** (Stop hook — replaces or supplements `validate-gm-response.sh`)

This is a single comprehensive hook that performs both classification and validation in one pass:

**Pass 1 — Infer Classification:**
1. Read state.json for context (combat active? conditions? scene type?)
2. Scan transcript for CLI calls (same `grep emergence_cli` approach, but extract ALL subcommands into an array)
3. Apply inference rules (priority-ordered, same as Implementation 1)
4. If no CLI calls found, analyze response content:
   - If response is <50 words → classify as META
   - If response contains OOC markers → classify as META
   - If response resolves a player action narratively → classify as UNRESOLVED_ACTION (violation)
   - Otherwise → classify as MISSING_PRESSURE (violation)

**Pass 2 — Validate Completeness:**
Based on inferred type, check required components:

```bash
case "$INFERRED_TYPE" in
  "MOVE_RESOLUTION")
    # Check: forced consequence narrated if present (delegate to existing hook)
    # Check: state.json updated with move results
    ;;
  "FREE_NARRATION")
    # Check: scene-pressure output present in response
    # Check: GM moves from scene-pressure were narrated (not cherry-picked)
    ;;
  "SCENE_TRANSITION")
    # Check: world-tick was called
    # Check: at least 1 clock-tick was called
    # Check: World Pulse block is in response
    ;;
  "COMBAT_PLAYER")
    # Delegate to existing combat hooks
    ;;
  "UNRESOLVED_ACTION")
    # BLOCK: "You resolved a player action without CLI. Run 'move' or 'scene-pressure'."
    ;;
  "MISSING_PRESSURE")
    # BLOCK: "No CLI executed and response contains narrative. Run 'scene-pressure' at minimum."
    ;;
esac
```

**Pass 3 — Persist Classification:**
Write classification to state.json `meta.turn_audit`:
```json
{
  "meta": {
    "turn_audit": {
      "last_turn": {
        "number": 14,
        "type": "move_resolution",
        "cli_commands": ["move"],
        "violations": [],
        "timestamp": "2026-02-21T14:30:00Z"
      },
      "classification_history": [
        {"turn": 13, "type": "free_narration", "cli": ["scene-pressure"]},
        {"turn": 14, "type": "move_resolution", "cli": ["move"]}
      ]
    }
  }
}
```

This uses the existing `meta` freeform object in state.json — no schema changes needed. The `inject-state-context.sh` hook already reads state.json, so the classification history is automatically available in context every turn, providing a self-reinforcing memory of what classification looks like.

**Modified file: `.claude/hooks/inject-state-context.sh`**
- Reads `meta.turn_audit.last_turn` from state.json
- Appends to the context injection:
  ```
  LAST TURN: [type] — CLI commands: [list]
  REMINDER: Every turn must execute at least one CLI command.
  - Action with uncertain outcome → run 'move' CLI
  - Certain outcome / no stakes → run 'scene-pressure' CLI
  - Scene transition → run 'world-tick' + 'clock-tick'
  - Combat → run appropriate combat CLI
  - Meta/OOC only → no CLI needed (keep response under 50 words)
  ```

**New file: `phases/2-action-interpretation/skills/turn-classification-enforcement.md`**
- Skill file documenting the automated classification system
- Lists all turn types, their inference rules, and required CLI commands
- References: `hard-rules.md` §5, `gm-protocol.md` §Free Narration Pressure

**Modified file: `phases/phase-manifest.md`**
- Phase 2 entry updated: `hooks: classify-and-validate-turn.sh`
- Phase 6 entry updated: additional validator listed

### Inference Rules (Detailed, Priority-Ordered)

```bash
# Ordered by specificity — first match wins

1. session-zero called              → SESSION_SETUP
2. character called (no combat)     → CHARACTER_MANAGEMENT
3. combat_active in state.json:
   a. evaluate-behavior called      → COMBAT_ENEMY_TURN
   b. round-end called              → COMBAT_ROUND_END
   c. attack called                 → COMBAT_PLAYER_TURN
   d. turn-start called only        → COMBAT_TURN_START
   e. (no combat CLI but in combat) → COMBAT_MISSING_CLI ← violation
4. downtime called                  → DOWNTIME
5. world-tick called                → SCENE_TRANSITION
6. move called                      → MOVE_RESOLUTION
7. scene-pressure called            → FREE_NARRATION
8. npc|relationship|diplomacy       → SOCIAL_INTERACTION
9. scene|creature|creatures         → ENCOUNTER_SETUP
10. loot called                     → LOOT_ROLL
11. roll called (standalone)        → BASIC_CHECK
12. No CLI + response < 50 words    → META (allowed)
13. No CLI + OOC markers            → META (allowed)
14. No CLI + narrative resolution   → UNRESOLVED_ACTION ← violation
15. No CLI + narrative (no resolve) → MISSING_PRESSURE ← violation
```

### Narrative Resolution Detection (for Rules 14-15)

Replace the brittle regex from `validate-gm-response.sh` with a more comprehensive check:

```bash
# Positive signals: GM narrated an action outcome
RESOLVES_ACTION=false
if echo "$LAST_ASSISTANT" | grep -qiE \
  "you (succeed|manage|fail|stumble|slip|sneak|convince|find|discover|dodge|block|land|hit|miss|struggle|push|climb|jump|break|pick|grab|escape|avoid|resist|overcome|reach|cross|enter|open|unlock|solve|figure|notice|spot|detect|sense|hear|smell|feel|read|decipher|translate|craft|build|repair|cook|treat|bandage|heal|negotiate|barter|trade|persuade|deceive|intimidate|charm|calm|rally|inspire|provoke|taunt|challenge)" \
; then
  RESOLVES_ACTION=true
fi

# Also check for past-tense resolution without "you" subject
if echo "$LAST_ASSISTANT" | grep -qiE \
  "the (lock|door|wall|barrier|trap|puzzle|mechanism|device) (opens|breaks|yields|gives|activates|disarms|clicks|releases)" \
; then
  RESOLVES_ACTION=true
fi

# Negative signals: response is purely atmospheric/descriptive (no resolution)
if echo "$LAST_ASSISTANT" | grep -qiE \
  "what do you do\?$|what do you say\?$|how do you respond\?$" \
; then
  # Ends with a question prompt — this is scene-setting, not resolution
  # Unless it ALSO contains resolution verbs above
  if [ "$RESOLVES_ACTION" = false ]; then
    RESOLVES_ACTION=false  # Pure scene-setting, no violation
  fi
fi
```

### Scope Assessment

| Surface | Touched? | Details |
|---|---|---|
| Validation/hooks | Yes | 1 new Stop hook, 1 modified UserPromptSubmit hook |
| Phase skills | Yes | New skill in Phase 2 |
| Phase manifest | Yes | Phase 2 + Phase 6 updated |
| State schema | **No** | Uses existing `meta` freeform object |

**Surfaces touched: 3** — at scope limit.

### Pros
- **Zero GM burden** — fully automatic classification and validation
- **Self-reinforcing** — classification history in context injection fights context decay
- **Single hook replaces multiple concerns** — classification, validation, and audit in one
- **Comprehensive violation detection** — broader regex coverage than current `validate-gm-response.sh`
- **Audit trail in state.json** — survives session boundaries, available for post-session analysis
- Context injection of last turn type acts as a soft reminder every turn

### Cons
- The comprehensive Stop hook is complex (~200 lines of bash)
- Inference is still heuristic — can be wrong for unusual turn structures
- Writing to `meta.turn_audit` on every turn adds I/O
- The classification history array in state.json will grow unbounded (needs periodic truncation)
- Replaces/overlaps with existing `validate-gm-response.sh` — need to carefully avoid double-checking

### History Truncation Strategy
Keep only the last 10 turns in `classification_history` to prevent unbounded growth:
```bash
# After writing new entry, truncate to last 10
jq '.meta.turn_audit.classification_history =
  (.meta.turn_audit.classification_history | .[-10:])' state.json > tmp.json
mv tmp.json state.json
```

---

## Comparison Matrix

| Criterion | Impl 1 | Impl 2 | Impl 3 | Impl 4 | Impl 5 |
|---|---|---|---|---|---|
| **GM burden** | None | Low (reads injection) | Medium (must call CLI) | Medium (must write header) | None |
| **Classification accuracy** | Good (inferred) | Good (guided) | Best (deterministic) | Variable (GM declares) | Good (inferred) |
| **Audit trail** | Turn receipt file | Turn receipt file | CLI output JSON | JSONL log file | state.json meta |
| **Context decay resistance** | None | High (injection) | Medium (CLI output in context) | Medium (header pattern) | High (history in injection) |
| **Surfaces touched** | 3 | 3 | 4 (needs phased PRs) | 3 | 3 |
| **Implementation complexity** | Medium | Medium | High | Low | Medium-High |
| **Testability** | Manual only | Manual only | CI-testable (Python) | Manual only | Manual only |
| **New Python code** | No | No | Yes (classify_action.py) | No | No |
| **Schema changes** | No | No | No | No | No |
| **Prevents drift vs. catches drift** | Catches | Prevents + catches | Prevents + catches | Prevents + catches | Catches + reinforces |

### Recommendation

**Implementation 5 (Dual-Phase Validation + Persistent Audit)** provides the best balance:
- Zero GM burden (unlike Impl 3, 4)
- Self-reinforcing context decay resistance (unlike Impl 1)
- Stays within 3-surface scope limit (unlike Impl 3)
- Comprehensive violation detection with broader coverage than current hooks
- Audit trail in state.json survives session boundaries

**If testability is critical,** combine Implementation 3 (Python classifier) with Implementation 5 (validation + audit). This requires phased PRs but gives CI-testable classification logic plus automated enforcement. The Python classifier can be added in PR 1 and the enforcement hook in PR 2.

**If minimal disruption is the priority,** Implementation 2 (Pre-Classification Injection) is the lightest lift — it enhances an existing hook and adds one new one, while proactively guiding the GM before it can drift.

---

## Files Referenced

| File | Role |
|---|---|
| `.claude/hooks/validate-gm-response.sh` | Current primary enforcement — to be supplemented or replaced |
| `.claude/hooks/inject-state-context.sh` | Context injection — enhanced in Impl 2, 4, 5 |
| `.claude/hooks/enforce-state-save.sh` | State persistence — audit data piggybacked here |
| `.claude/settings.json` | Hook registration — new hooks registered here |
| `runtime/phases/2-action-interpretation/CLAUDE.md` | Currently advisory — gains enforcement in all implementations |
| `runtime/phases/2-action-interpretation/skills/action-classification.md` | Current advisory skill — supplemented by new skill |
| `runtime/phases/phase-manifest.md` | Phase 2 entry updated in all implementations |
| `runtime/turn-loop.md` | Turn protocol — not modified but referenced |
| `runtime/phases/1-context-loading/references/hard-rules.md` | Rule #5 (scene-pressure mandate) |
| `runtime/phases/1-context-loading/references/gm-protocol.md` | §When NOT to Roll, §Free Narration Pressure |
| `runtime/scripts/CLAUDE.md` | Script registry — updated in Impl 3 only |
| `runtime/phases/3-resolution/skills/exploration/scene-pressure.md` | Scene-pressure skill — referenced by all implementations |
