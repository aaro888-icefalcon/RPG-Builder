# Analysis: Constraint Interpretation Drift — "Free Narration" Override

- **Date:** 2026-02-20
- **Trigger:** During gameplay, the GM repeatedly classified player actions as "free narration" and stopped following repository constraints (skipping CLI execution, not running scene-pressure, narrating outcomes without mechanical backing).
- **Severity:** High — undermines the core determinism guarantee of the system.

---

## Root Cause Analysis

### Primary Root Cause: Phase 2 Has Zero Enforcement

Phase 2 (Action Interpretation) is the **only advisory phase** in the pipeline. It has no hooks, no validators, and no automated checks. The phase-manifest explicitly states: `hooks: (none — advisory phase)`.

This means the decision of whether a player action triggers a CLI command (`move`, `attack`, etc.) or falls into "free narration" (`scene-pressure`) is entirely at the GM's discretion with no mechanical guardrail. Once the GM incorrectly classifies an action as "no risk, certain outcome" (the criteria in `gm-protocol.md` §When NOT to Roll), the system has no way to detect or correct this misclassification.

### Contributing Causes

#### 1. Context Window Decay

As conversations grow long, the procedural rules from `hard-rules.md`, `gm-protocol.md`, and phase CLAUDE.md files drift out of the model's active context window. The `inject-state-context.sh` hook re-injects **state data** (HP, inventory, clocks) every turn but does NOT re-inject the **procedural rules** (when to roll, when to run scene-pressure, the pre-response checklist). The model gradually "forgets" that free narration still requires `scene-pressure` execution.

#### 2. Weak Action Detection in validate-gm-response.sh

Violation 1 in `validate-gm-response.sh` (lines 83-96) attempts to detect "player took action but no CLI ran" using two fragile mechanisms:

- **Input pattern matching** (line 83): Only catches actions starting with `"I try|want|go|head|walk|run|attack|..."`. Player messages phrased differently (e.g., "Let's check the building," "Can I search the area?", or narrative-style declarations) bypass this entirely.
- **Output pattern matching** (line 93): Only catches responses containing `"you succeed|manage|slip|sneak|..."`. If the GM uses different resolution language, the violation goes undetected.

Together, these mean a large class of unresolved player actions slip through without triggering the validator.

#### 3. No Dedicated scene-pressure Execution Check

The system mandates `scene-pressure` on EVERY free narration turn (hard-rules.md rule #5). But `validate-gm-response.sh` only checks whether ANY `emergence_cli` call was made (line 70: `grep -c "emergence_cli"`). It does not specifically check that `scene-pressure` was called on turns classified as free narration. A turn with zero CLI calls that doesn't match the action patterns in Violation 1 passes all validators silently.

#### 4. RPG Session Detection Fragility

All Stop hooks use keyword-based session detection (grep for `"emergence|what do you do|emergence_cli|state\.json|..."` in the last 20-30 transcript lines). During extended narrative passages where these keywords don't appear, the validators may decide they're "not in an RPG session" and exit early (`IN_RPG_SESSION=false`, line 49 of `validate-gm-response.sh`). This creates windows where no validation occurs at all.

#### 5. Stop Hook Retry Bypass

All Stop hooks check `stop_hook_active` and exit immediately if true (e.g., `validate-gm-response.sh` line 18). This prevents infinite loops but means: if the first retry attempt fixes Violation 2 (missing "What do you do?") but introduces a new Violation 1 (resolving without CLI), the second violation won't be caught on the retry pass.

#### 6. No Classification Audit Trail

Phase 2 produces no artifact documenting its classification decision. There's no "I classified this as free narration because [criteria X, Y, Z]" output that could be validated by downstream phases. The classification is implicit — it simply results in either calling a CLI command or not.

---

## Impact Assessment

When the GM drifts into unconstrained free narration:

1. **Determinism breaks** — outcomes are improvised rather than CLI-determined
2. **State diverges from truth** — narrated events may not match state.json
3. **Scarcity erodes** — without scene-pressure, no GM moves fire, clocks don't tick, no new threats appear
4. **Power fantasy creeps in** — without mechanical constraints, the GM defaults to satisfying narrative arcs
5. **Forced consequences are skipped** — no CLI call means no forced consequence selection

---

## Five Alternate Fix Plans

Each plan targets a different layer of the problem. Plans are ordered from most surgical (narrowest scope) to most architectural (broadest scope).

---

### Plan A: Strengthen validate-gm-response.sh Detection (Surgical Hook Fix)

**Scope:** `.claude/hooks/validate-gm-response.sh` only
**Surfaces touched:** 1 (Validation/hooks)

**Changes:**
1. Replace the brittle regex action detection (line 83) with a broader heuristic: any user message that isn't explicitly OOC (prefixed with `//`, `OOC:`, or `[meta]`) is treated as a potential gameplay action.
2. Add a dedicated Violation for missing `scene-pressure`: if no `emergence_cli` call was made this turn AND the response contains narrative resolution (more than 100 words of prose), block with a specific "MISSING SCENE-PRESSURE" violation.
3. Strengthen RPG session detection: in addition to keyword grep, check for the existence of an active `state.json` file (if it exists, we're in a session — period).
4. Add a Violation 9 that specifically checks: if no CLI subcommand was called at all this turn (zero `emergence_cli` invocations) and the response is longer than 50 words, block with "NO CLI EXECUTION: Every GM turn must execute at least one CLI command (move, scene-pressure, clock-tick, etc.)."

**Pros:**
- Smallest possible diff — single file edit
- Immediately deployable, no structural changes
- No approval gates triggered (no schema changes, no turn-loop contract changes)

**Cons:**
- Still regex-based — detection will always have edge cases
- Doesn't address the root cause (Phase 2 has no enforcement)
- Doesn't address context window decay

**Integration touchpoints:** 4 (phase-manifest.md hooks list), 5 (skill files referencing this hook)
**Validation:** Run `python runtime/tests/run_all_tests.py 1`, manual play-test

---

### Plan B: Add Procedural Rule Re-injection Hook (Context Decay Fix)

**Scope:** New hook + `inject-state-context.sh` enhancement
**Surfaces touched:** 2 (Validation/hooks, Phase skills)

**Changes:**
1. Expand `inject-state-context.sh` to append a condensed "Procedural Reminder" block after the state data. This block would contain:
   - The 4 criteria for "When NOT to Roll" (from gm-protocol.md)
   - The mandate: "If no roll → run scene-pressure. ALWAYS."
   - The pre-response checklist items most commonly violated
   - Current phase identification prompt: "What phase am I in? EXPLORATION / COMBAT / SOCIAL / DOWNTIME?"
2. Keep the reminder compact (under 500 tokens) to avoid bloating context.
3. Update the scene-pressure skill file's "Hooks That Enforce This" section to reference this enhancement.

**Pros:**
- Directly fights context window decay — the #1 contributing cause
- Works within the existing hook infrastructure
- Small diff, no new hook registration needed (enhances existing hook)
- Re-injects rules EVERY turn, so drift can't accumulate

**Cons:**
- Adds ~500 tokens to every turn's context (minor cost)
- Advisory, not enforced — the model can still ignore the reminder
- Doesn't add a mechanical check for scene-pressure execution

**Integration touchpoints:** 5 (update skill files' "Hooks That Enforce This")
**Validation:** Run `python runtime/tests/run_all_tests.py 1`, manual play-test for 10+ turns

---

### Plan C: Add Phase 2 Classification Enforcement Hook (Structural Fix)

**Scope:** New hook + new skill file + settings.json update
**Surfaces touched:** 3 (Validation/hooks, Phase skills, Phase manifest) — hits scope limit

**Changes:**
1. Create a new PostToolUse hook `validate-action-classification.sh` that fires after the GM's first tool call (or lack thereof) in a turn.
2. The hook inspects the transcript to determine: did the GM call any CLI command? If yes, which one? If no, did the response attempt to resolve a player action narratively?
3. If the GM resolved an action without any CLI call:
   - Check if the response narrates a player-initiated outcome (uses second-person past tense: "you find," "you manage," "you convince")
   - If found, block with: "ACTION RESOLVED WITHOUT CLI. Classify this action and run the appropriate CLI command before narrating."
4. Register the hook in `.claude/settings.json` under the `Stop` event array.
5. Create `phases/2-action-interpretation/skills/classification-enforcement.md` documenting the new enforcement.
6. Update `phases/phase-manifest.md` Phase 2 entry to list the new hook (changing it from "no hooks" to having enforcement).

**Pros:**
- Addresses the root cause: Phase 2 is no longer advisory-only
- Catches misclassification regardless of how the player phrases their action
- Structural improvement that strengthens the whole pipeline

**Cons:**
- Touches 3 major surfaces (hooks, skills, manifest) — at the scope limit
- Changes the Phase 2 contract from "advisory" to "enforced" — a pipeline contract change
- More complex hook logic than Plan A
- Requires updating design docs that describe Phase 2 as advisory

**Integration touchpoints:** All 7 (new skill, phase index.md, phase CLAUDE.md, manifest, hook, script registry if applicable, tests)
**Validation:** Run full test suite + `validate_docs_structure.py` + manual play-test

---

### Plan D: Structured Turn Receipt with Classification Audit (Observability Fix)

**Scope:** New turn-receipt field + enhanced state persistence + validation
**Surfaces touched:** 3 (State schema, Phase skills, Validation/hooks)

**Changes:**
1. Add a `turn_classification` field to the turn receipt format, requiring the GM to explicitly declare:
   - `action_type`: the classified action type (move, attack, free_narration, scene_transition, etc.)
   - `cli_commands_executed`: list of CLI commands run this turn
   - `scene_pressure_required`: boolean — was this a free narration turn?
   - `scene_pressure_executed`: boolean — was scene-pressure actually run?
2. Add a Stop hook `validate-turn-classification.sh` that checks:
   - If `scene_pressure_required=true` but `scene_pressure_executed=false`, block.
   - If `action_type=free_narration` but no `scene-pressure` in `cli_commands_executed`, block.
   - If `cli_commands_executed` is empty and `action_type` is not `meta` or `ooc`, block.
3. Update `phases/5-persistence/skills/state-persistence.md` to require the classification fields in every turn receipt.
4. The audit trail enables post-session analysis to identify classification drift patterns.

**Pros:**
- Creates an observable, auditable classification decision
- Enables retroactive analysis ("when did the GM start drifting?")
- Turn receipts are already a first-class concept in the system
- The explicit declaration forces the GM to think about classification

**Cons:**
- Adds overhead to every turn (GM must declare classification)
- Touches state schema — triggers approval gate for schema_version bump
- More complex than Plans A/B
- The GM can still declare incorrectly (though the hook will catch obvious mismatches)

**Integration touchpoints:** Full cross-cutting checklist (§5 in change-integration-checklist.md)
**Validation:** Full test suite + state validator + schema migration notes

---

### Plan E: Two-Phase Enforcement — Classify-Then-Confirm Gate (Architectural Fix)

**Scope:** New phase workflow + two new hooks + CLAUDE.md contract change
**Surfaces touched:** 4+ (Phase skills, Hooks, Manifest, CLAUDE.md, turn-loop) — **requires phased PRs**

**Changes:**
1. Split Phase 2 into two sub-phases:
   - **Phase 2a — Classify:** GM declares the action classification and selected CLI command (or "free narration + scene-pressure").
   - **Phase 2b — Confirm:** A PreToolUse hook validates that the declared classification is consistent with the player's input before allowing CLI execution to proceed.
2. Create a new Stop hook `enforce-classification-declaration.sh` that blocks if the GM's response doesn't contain a classification block (formatted as a structured comment or metadata section).
3. Create a new PreToolUse hook `validate-classification-consistency.sh` that checks: if the GM declared "free narration" but is now trying to narrate an action outcome without running scene-pressure, block.
4. Update `runtime/turn-loop.md` to reflect the split Phase 2.
5. Update `runtime/CLAUDE.md` pipeline table.
6. Update `runtime/phases/phase-manifest.md`.

**Pros:**
- Most thorough solution — makes misclassification structurally impossible
- Creates a clear separation between "decide what to do" and "do it"
- The classification declaration is itself a form of chain-of-thought that improves accuracy
- Fully auditable — every turn has an explicit classification on record

**Cons:**
- Largest scope — touches 4+ major surfaces, MUST be split into phased PRs per repo guardrails
- Changes the turn-loop contract — triggers approval gate
- Adds latency to every turn (two-step classification process)
- Risk of over-engineering — adds structural complexity for a problem that might be solvable at the hook level
- Requires updating all documentation that references "6-phase pipeline"

**Integration touchpoints:** All 7 + turn-loop contract update + CLAUDE.md pipeline table
**Validation:** Full test suite + all validators + extended play-test session

---

## Recommendation Matrix

| Criterion | Plan A | Plan B | Plan C | Plan D | Plan E |
|---|---|---|---|---|---|
| Addresses root cause | Partial | No | Yes | Partial | Yes |
| Addresses context decay | No | Yes | No | No | Partial |
| Scope (surfaces touched) | 1 | 2 | 3 | 3 | 4+ |
| Requires approval gates | No | No | No | Yes (schema) | Yes (turn-loop) |
| Requires phased PRs | No | No | No | No | Yes |
| Implementation complexity | Low | Low | Medium | Medium | High |
| Risk of regressions | Low | Low | Medium | Medium | High |
| Effectiveness (estimated) | Moderate | Moderate | High | High | Very High |

**Suggested approach:** Combine Plan A + Plan B as a single PR (2 surfaces touched, under the limit). This provides immediate relief from both the detection gap and context decay. If drift persists after deployment, escalate to Plan C or Plan D.

---

## Files Referenced in This Analysis

| File | Role in the issue |
|---|---|
| `.claude/hooks/validate-gm-response.sh` | Primary enforcement hook — detection gaps identified |
| `.claude/hooks/inject-state-context.sh` | State re-injection — missing procedural rule re-injection |
| `.claude/hooks/validate-narrative-principles.sh` | Tone enforcement — works but doesn't catch missing CLI |
| `.claude/settings.json` | Hook registration — Phase 2 has no hooks registered |
| `runtime/phases/2-action-interpretation/CLAUDE.md` | Advisory-only phase declaration |
| `runtime/phases/phase-manifest.md` | Documents Phase 2 as hookless |
| `runtime/phases/1-context-loading/references/hard-rules.md` | Rule #5 (scene-pressure mandate) |
| `runtime/phases/1-context-loading/references/gm-protocol.md` | §When NOT to Roll, §Free Narration Pressure |
| `runtime/phases/3-resolution/skills/exploration/scene-pressure.md` | Scene-pressure skill file |
| `runtime/turn-loop.md` | 8-step turn protocol |
| `runtime/CLAUDE.md` | Runtime governance — 7 hard rules |
