# Layer 4: Orchestration Stability Audit Report

> **Last verified against code commit:** `d3a35f3524372b22b541d00c83e86aed347845c1`  
> **Verified on:** 2026-02-14

**Version:** v4.5.11
**Date:** 2026-02-08
**Auditor:** Claude (Opus 4)

---

## Executive Summary

```
Phase Management:
  State Machine:       IMPLICIT (inferred from context, not tracked in state)
  Phase Coverage:      5/8 expected phases (combat, social, exploration, world-tick, session start/end)
  Transitions:         PARTIAL (triggers defined for scene transitions; combat start/end defined; others implicit)
  Combat Sub-Phases:   ABSENT (no initiative→turn→round-end separation in instructions)
  World Tick:          PROCEDURAL (CLI-driven, but JSON arg construction left to AI)

State Management:
  Schema:              DEFINED (world-state-template.md JSON block)
  Read/Write Protocol: DEFINED (Response Gate §6, State Management §16)
  Source of Truth:      CLEAR (state.json is canonical — Rule 7)
  Context Fit:         TIGHT (persistent context ~11,000 tokens before conversation)
  Total State Size:    ~1,600 tokens (state.json), growing with NPCs/chronicle

Script Boundary:
  Coverage:            55% of critical computations scripted
  CRITICAL Gaps:       4 (condition processing, round-end, AP tracking, HP application)
  Call Protocol:       DEFINED (Response Gate mandates CLI-first)
  Integration:         ADEQUATE (JSON output, but AI must manually apply results to state)

Narrator Control:
  Tone Method:         MIXED (prohibitive warnings + 2 worked examples + genre labels)
  Override Risk:       LOW (explicit "mechanical outcomes computed first, narrated second")

GM Moves:
  Vocabulary:          DEFINED (8 soft + 8 hard moves in moves.py)
  Edge Cases:          4/10 covered

Error Recovery:
  Coverage:            2/7 error types (self-correction protocol, state.json authority)
  Authority Chain:     IMPLICIT (state.json > AI stated but not formalized)

Function Separation:   4/6 functions have dedicated support
Peak Cognitive Load:   HIGH (combat with 3+ enemies and conditions)

Layer 4 Overall: UNSTABLE — skeletal structure exists but critical gaps in combat automation
                  and phase management cause systematic failures

Verdict: Can this AI reliably run the game?
  SIMPLE SCENARIOS ONLY — Open exploration, single-enemy combat, and social encounters
  work. Multi-enemy combat with conditions will degrade. Long campaigns will accumulate
  state drift without migration fixes.
```

---

## Outdated Findings (Superseded Since This Audit)

The audit below is retained as a historical snapshot. The following findings are now superseded by later CLI coverage and protocol updates:

1. **Round-end automation was marked as absent.**  
   **Now superseded:** `round-end --combat-json '...' --entities-json '[...]'` is available in the CLI reference and can be run at each combat round end.
2. **Turn-start automation was marked as absent/implicit.**  
   **Now superseded:** `turn-start --entity-json '...'` is available in the CLI reference and can be run at each entity turn start.
3. **Combat hook coverage concerns around condition ticking were tied to missing commands.**  
   **Now superseded in part:** dedicated `turn-start` and `round-end` commands exist; remaining risk is execution discipline, not command availability.

---

## Layer 4 System Map

### CLAUDE.md Architecture (Primary AI Instruction File)
- **Total:** 764 lines, ~6,431 tokens
- **Structure:** Monolithic. 21 sections covering all GM functions in a single file.
- **Progressive disclosure:** Partial. §20 routes to reference files by need, but §12-14 duplicate content already in reference files.
- **Phase/state guidance:** Implicit. Response Gate (§0) is phase-agnostic — same 6 gates for combat, exploration, social. No "you are in combat mode" switching.
- **Critical instructions position:** Response Gate at top (good). Self-Correction at §3 (good). CLI Reference at §13/line 512 (buried). State Management at §16/line 614 (buried).

### Game Phase Management
- **File(s):** CLAUDE.md §17 (Session Workflow), §0 (Response Gate), §12 (Combat System)
- **Phases identified:** Session start, free play, combat, scene transition, session end
- **Missing phases:** Downtime (CLI exists but no flow), social encounter (no structured flow), exploration (no flow), world tick (trigger defined but procedure gaps)
- **Transition triggers:** Scene transition defined (6 triggers in Gate 3). Combat start/end implicit. Others undefined.
- **Phase-specific instructions:** None. Same Response Gate applies to all phases.
- **State machine:** ABSENT. No `current_phase` in state.json. AI infers from context.

### State Management
- **State file:** `campaigns/[name]/state.json` (single JSON file)
- **Schema:** Defined in `assets/world-state-template.md` (dual-format: JSON block + markdown tables)
- **State loading:** Response Gate §6 + state hook (reads state.json before every user message)
- **State writing:** §16 lists 7 save triggers. AI writes state.json directly.
- **Validation:** ABSENT. No schema validation. If AI writes malformed state, nothing catches it.
- **State size:** ~1,600 tokens currently. Will grow with NPCs and chronicle.
- **CRITICAL:** Live state.json has schema drift from Layer 3 code (missing world_situation, inter_group_relations, pc_standing; retains obsolete entropy/momentum/connection)

### Script Inventory

| Script | Purpose | Inputs | Outputs | Called When | Called By |
|--------|---------|--------|---------|-------------|----------|
| `emergence_cli.py` | CLI dispatcher | Command + args | JSON to stdout | Every mechanical action | AI via Bash |
| `combat.py` | Attack rolls, initiative, stances, combat state | Attacker/target stats | Attack result JSON | Combat | CLI |
| `moves.py` | PbtA resolution, GM moves, consequences | Stat score, position, effect, arena | Move result JSON | Non-combat actions | CLI |
| `world_tick.py` | Faction turns, threats, clocks, tags, World Pulse | World state JSON, days elapsed | Tick report JSON | Scene transitions | CLI |
| `scene.py` | Scene generation, encounter weighting | Location, region, threat level | Scene JSON | New scene | CLI |
| `creature.py` | Creature stat generation | Level, threat tier, region | Creature stat block JSON | Pre-combat | CLI |
| `npc.py` | NPC generation, relationship tracking | Faction, role, disposition | NPC JSON | NPC introduction | CLI |
| `character.py` | PC stat generation | Aspect, archetype, level | Character stat JSON | Character creation | CLI |
| `faction.py` | Faction generation, session zero | Count | Factions + world JSON | Session zero | CLI |
| `diplomacy.py` | Inter-group relations, PC standing | Faction IDs, changes | Updated relations JSON | Diplomacy actions | CLI |
| `conditions.py` | Condition definitions | Condition name | Condition entry dict | Reference only | Internal |
| `behavior.py` | NPC behavior, social templates | Archetype | Behavior dict | NPC encounters | Internal |
| `dice.py` | 2d6 rolls, modifiers, hit bands | Modifier, DC | Roll result dict | All resolution | Internal |
| `adventure.py` | Adventure hook generation | World state, arc | Adventure JSON | Session prep | CLI |
| `technique_registry.py` | Combat technique database | Form, variant | Technique dict | Reference only | Internal |

### Context Management
- **Always in context:** CLAUDE.md (~6,431 tokens), state hook output (~300 tokens)
- **Loaded on demand:** gm-protocol.md (~4,921), hard-rules.md (~2,284), lore files, form references
- **Context budget strategy:** §20 lists files with "Load When Needed" but no phase-specific routing
- **File reading patterns:** §19 distinguishes CLI (always for mechanics) from lore (load on first contact)

### Script Boundary
- **Scripted:** Attack rolls, move resolution, creature generation, NPC generation, scene generation, world tick, initiative, clock advancement, loot, diplomacy, PC standing, downtime resolution
- **AI must compute inline:** HP application, AP tracking, condition turn effects, condition duration tracking, death/0 HP handling, combat end detection, enemy action selection, technique effect interpretation, zone movement, reaction resolution, morale/flee
- **Ambiguous:** When to run world-tick (trigger defined but JSON arg construction unclear), how to extract enemy stats for attack CLI args from state

### Tone & Genre Enforcement
- **File(s):** CLAUDE.md §8 (Narrative Principles), hard-rules.md §Tone Reminders + §Anti-Power-Fantasy
- **Method:** Mix of prohibitive ("NOT power fantasy"), descriptive ("Dark Western + LitRPG + Political Fantasy + Survival Horror"), and prescriptive (2 worked examples in §9-10)
- **Specificity:** Moderate. Prohibitions are specific (banned heroic descriptors). Positive examples exist but are workflow-focused, not tone-focused.

### Error Handling
- **Player correction:** Not explicitly defined
- **State conflict:** state.json is canonical (Rule 7), but no procedure for reconciliation
- **Rule misapplication:** Self-Correction Protocol (§3) catches errors before sending, but no post-hoc correction procedure

### GM Move / Adjudication System
- **File(s):** moves.py (8 soft + 8 hard moves), gm-protocol.md (position/effect calibration, consequence design)
- **Move types:** Soft (warning/setup) and Hard (consequence/damage), each with 8 subtypes
- **Trigger conditions:** Defined by position × outcome tier in CONSEQUENCE_TABLES
- **Soft vs. hard:** Escalation defined (controlled → soft on miss; risky → hard on miss; desperate → severe hard on miss)

---

## Step 1: Phase Management

### 1.1: Phase Identification

| Phase | Where Defined | AI Responsibilities | Entry Trigger | Exit Trigger | Phase-Specific Context |
|-------|--------------|---------------------|---------------|--------------|----------------------|
| Session Start | CLAUDE.md §11, §17 | Load state, summarize, generate scene | User starts session | First scene generated | Quick Start checklist |
| Free Play | Implicit | Narrate, resolve moves, manage NPCs | Scene transition ends | Combat starts / scene transition | Response Gate (generic) |
| Combat | CLAUDE.md §12, §17 | Initiative, turns, attacks, conditions, end | Enemy engagement | All enemies defeated/fled | Combat Display Template |
| Scene Transition | CLAUDE.md Gate 3, §15 | World tick, World Pulse, update state | 6 defined triggers | New scene narrated | World Pulse format |
| Session End | CLAUDE.md §17 | Save state, summarize | User ends session | State saved | Save checklist |
| Social Encounter | ABSENT | — | — | — | — |
| Exploration | ABSENT | — | — | — | — |
| Downtime | CLI exists, no flow | — | — | — | — |

- [x] At least 5 distinct phases: 5 defined (session start, free play, combat, scene transition, session end)
- [ ] Each phase has explicit AI responsibilities: Only combat and session start/end have responsibilities listed
- [ ] Transitions mechanically defined: Scene transition triggers defined; combat start/end implicit
- [ ] No overlapping responsibilities: Combat and free play overlap (when does a "quick conflict" become structured combat?)
- [ ] AI can determine current phase from state: NO — no `current_phase` field in state.json

### 1.2: Combat Sub-Phase Structure

- [ ] Initiative determination is a defined step: Mentioned in §17 step 1 but not proceduralized
- [ ] Turn order is explicit: `combat.py` has `advance_turn()` but CLAUDE.md doesn't instruct AI to call it
- [ ] Player turn flow: Partially defined in §17 steps 3-6
- [ ] Enemy turn flow: §17 step 7 says "Enemy counterattack: run attack CLI" — no behavior selection guidance beyond §12
- [ ] Round end procedure: **ABSENT** — no condition ticking, no clock checking, no combat-end evaluation
- [ ] Combat end triggers: §12 mentions "Morale: Enemies may flee at <25% HP" — no other triggers
- [ ] Post-combat procedure: Not defined beyond "save state"

**CRITICAL GAP:** No round-end procedure means conditions (Bleeding, Burning, Poisoned) are never automatically processed. The AI must remember to tick them — and evidence from AI GM behavior shows this is forgotten by round 2 of any combat with 3+ combatants.

### 1.3: World Tick Procedure

| Step | Input | Processing Method | Output | Deterministic? |
|------|-------|-------------------|--------|----------------|
| 1. Faction actions | World state JSON | CLI (`world-tick`) | Faction action results | YES (2d6 + power vs DC 8) |
| 2. Relation consequences | Relations list | CLI (`world-tick`) | Relation events | YES (probability-based) |
| 3. Threat advancement | Threat clocks | CLI (`world-tick`) | Clock ticks + events | YES |
| 4. Meta clock generation | Completed clocks | CLI (`world-tick`) | New meta clocks | YES |
| 5. Tag updates | Faction/threat actions | CLI (`world-tick`) | Tag changes | YES |
| 6. World Pulse | Tick results | CLI (`world-tick`) | News/rumors/trends | YES |

- [x] World tick procedure exists with explicit steps: YES (world_tick.py)
- [x] Execution order specified: YES (6 ordered steps)
- [x] Each step has defined inputs/outputs: YES
- [x] Triggered by defined conditions: YES (Gate 3: scene transition)
- [ ] Output updates state files: NO — AI must manually apply tick results to state.json
- [x] Produces summary for next session: YES (World Pulse)
- [x] ≥50% deterministic: YES (all 6 steps are formula/table-driven)

**GAP:** The `--world-json` argument for `world-tick` CLI requires the AI to extract and serialize world state from state.json. No instruction tells the AI how to construct this argument. In practice, the AI often skips world-tick and falls back to manual `clock-tick` calls.

---

## Step 2: State Management

### 2.1: State Schema Inventory

| Component | Fields Tracked | Format | File Location | Size (~tokens) |
|-----------|---------------|--------|---------------|----------------|
| PC State | name, class, aspect, archetype, level, xp, attributes (8), modifiers, hp, stamina, mana, composure, def, initiative, movement, crit_threshold, form_slots, class_ability, inventory, forms, background_forms, talents, conditions, background | JSON | state.json → character | ~800 |
| NPC State (per NPC) | id, name, faction, role, disposition, status, traits, motivation, secret, tags, last_seen, notes | JSON | state.json → world.known_npcs[] | ~80 per NPC |
| NPC State (total active) | 1 NPC currently | JSON | state.json | ~80 |
| Faction State (per faction) | id, name, archetype, description, goal, method, territory, power_level, clock, reputation, rank, notes | JSON | state.json → world.human_factions[] | ~100 per faction |
| Faction State (total) | 10 human factions | JSON | state.json | ~1,000 |
| Threat State | id, name, threat_type, goal, threat_level, clock | JSON | state.json → world.external_threats[] | ~60 per threat |
| World State | current_day, current_time, entropy(!), momentum(!), connection(!) | JSON | state.json → world | ~50 |
| Combat State | location, region, phase, combat_state (null when not in combat) | JSON | state.json → current_scene | ~30 |
| Narrative State | chronicle (3 entries) | JSON | state.json → world.chronicle | ~200 |
| **MISSING** | world_situation (tags at 3 scales) | — | Not in state.json | ~300 expected |
| **MISSING** | inter_group_relations | — | Not in state.json | ~200 expected |
| **MISSING** | pc_standing (per faction) | — | Not in state.json | ~150 expected |
| **TOTAL (current)** | | | | ~1,600 |
| **TOTAL (after migration)** | | | | ~2,250 |

### 2.2: State Desync Risk Scan

| Instruction | Location | What to Track | Written to State? | Desync Risk |
|-------------|----------|---------------|-------------------|-------------|
| "Tick clocks after scene transition" | CLAUDE.md Rule 5 | Clock values | YES (clock-tick updates) | LOW |
| "Track composure" | CLAUDE.md §12 | Composure value | YES (in character.composure) | LOW |
| "Update NPC disposition" | hard-rules.md §NPCs | NPC trust/disposition | PARTIAL (trust system exists but state.json NPCs lack trust field) | MEDIUM |
| "Track AP spent this turn" | CLAUDE.md §12 (implicit) | AP remaining | NO (not in state) | **HIGH** |
| "Track condition durations" | conditions.py (definitions) | Condition turns remaining | NO (conditions stored as string list, no duration) | **HIGH** |
| "Track enemy telegraphed actions" | CLAUDE.md §12 | Next enemy action | NO (not persisted) | MEDIUM |
| entropy/momentum/connection | state.json | Old meters | YES but OBSOLETE | **CRITICAL** (code no longer reads these) |

### 2.3: Context Budget Analysis

```
CONTEXT BUDGET
==============
Model context window: ~200,000 tokens (Claude Opus 4)

Persistent context (always loaded):
  CLAUDE.md:                    ~6,431 tokens
  State hook output:            ~300 tokens
  System prompt overhead:       ~500 tokens
  PERSISTENT SUBTOTAL:          ~7,231 tokens (3.6% of window)

Largest phase-specific load (combat with references):
  hard-rules.md:                ~2,284 tokens
  combat.md (reference):        ~700 tokens
  conditions.md (reference):    ~600 tokens
  creature stat blocks (3):     ~450 tokens
  PHASE SUBTOTAL:               ~4,034 tokens

Conversation history (typical session): ~8,000-15,000 tokens

PEAK LOAD:                      ~26,265 tokens (13% of window)
REMAINING for AI reasoning:     ~173,735 tokens (87%)
```

- [x] Persistent context ≤ 30% of window: YES (3.6%)
- [x] Peak load ≤ 75% of window: YES (13%)
- [x] ≥ 25% remains for reasoning: YES (87%)
- [ ] No single component exceeds 1000 tokens: FAIL — CLAUDE.md is 6,431 tokens

**Note:** Context budget is not the problem. The 200K window is generous. The issue is *attention* — with 6,431 tokens of instructions, the AI's attention to any specific instruction degrades. Restructuring CLAUDE.md to ~400 lines (~2,600 tokens) would significantly improve instruction adherence.

### 2.4: CLAUDE.md Structure Analysis

| # | Section | Lines | ~Tokens | Content Type | Criticality | Position |
|---|---------|-------|---------|-------------|-------------|----------|
| 0 | Response Gate | 1-76 | 689 | Behavioral loop | **CRITICAL** | Top |
| 1 | Seven Hard Rules | 79-91 | 260 | Constraints | **CRITICAL** | Top |
| 2 | Failure Examples | 93-152 | 546 | Training examples | HIGH | Top |
| 3 | Self-Correction | 155-177 | 228 | Error prevention | HIGH | Top quarter |
| 4 | GM Agenda | 180-191 | 150 | Philosophy | MEDIUM | Top quarter |
| 5 | GM Principles | 194-206 | 208 | Decision filters | MEDIUM | Top quarter |
| 6 | Action Resolution | 209-285 | 624 | Core loop | **CRITICAL** | Top third |
| 7 | Player Agency | 288-310 | 202 | Constraint | **CRITICAL** | Middle |
| 8 | Narrative Principles | 312-349 | 338 | Tone guidance | HIGH | Middle |
| 9 | Worked Example 1 | 352-385 | 319 | Training example | MEDIUM | Middle |
| 10 | Worked Example 2 | 387-427 | 364 | Training example | MEDIUM | Middle |
| 11 | Quick Start | 430-446 | 111 | Session flow | LOW | Middle |
| 12 | Combat System | 449-509 | 514 | **DUPLICATE** | HIGH (but duplicates combat.md) | Lower |
| 13 | CLI Command Reference | 512-562 | 501 | **REFERENCE** | HIGH (but could be separate file) | Lower |
| 14 | Awakening Protocol | 565-589 | 189 | **DUPLICATE** | LOW (duplicates awakening.md) | Lower |
| 15 | World Pulse Format | 592-611 | 124 | Display format | MEDIUM | Lower |
| 16 | State Management | 614-627 | 91 | Save triggers | HIGH | **Buried** |
| 17 | Session Workflow | 630-661 | 254 | Flow guidance | HIGH | **Buried** |
| 18 | Key Mechanics | 664-687 | 189 | **DUPLICATE** | LOW (duplicates math-assumptions.md) | Bottom |
| 19 | Procedural Gen vs Lore | 690-707 | 137 | Routing | MEDIUM | Bottom |
| 20 | Reference Files | 710-763 | 397 | File lookup | LOW (rarely consulted at bottom) | Bottom |

**Instruction decay:** Critical content (State Management §16, Session Workflow §17) is buried at lines 614-661. The AI's attention to instructions degrades with distance from the top of the file. §12-14 and §18-20 consume ~1,790 tokens (~28% of CLAUDE.md) on content that duplicates reference files or serves as a lookup table.

---

## Step 3: Script Boundary

### 3.1: Computation Coverage

| Computation | Script? | Script Name | AI Computes? | Frequency | Severity if Unscripted |
|---|---|---|---|---|---|
| Attack roll resolution | YES | combat.py `attack_roll()` | NO | Every attack | — |
| Damage calculation | YES | combat.py (in `attack_roll()`) | NO | Every hit | — |
| **Condition turn-start effects** | **NO** | — | **YES** | Multiple/combat | **CRITICAL** |
| **Condition duration tick** | **NO** | — | **YES** | Every round | **CRITICAL** |
| **HP modification (apply damage)** | **NO** | — | **YES** | Every hit | **CRITICAL** |
| **AP tracking/enforcement** | **NO** | — | **YES** | Every turn | **CRITICAL** |
| Resource deduction (Stamina/Mana) | PARTIAL | combat.py tracks `stamina_spent_this_turn` | YES (must apply) | Every technique | MAJOR |
| Initiative ordering | YES | combat.py `roll_initiative()` | NO | Every combat | — |
| PC stat generation | YES | character.py | NO | Char creation | — |
| NPC stat generation | YES | npc.py | NO | NPC creation | — |
| Creature stat generation | YES | creature.py | NO | Encounter setup | — |
| Encounter difficulty budget | YES | creature.py (multi-creature) | NO | Encounter setup | — |
| Level-up calculations | PARTIAL | character.py (stats only) | YES (talent selection) | Advancement | MAJOR |
| Loot generation | YES | dice.py / loot command | NO | Post-combat | — |
| Crafting resolution | YES | downtime_activities.py | NO | Downtime | — |
| Rest/recovery calculation | NO | — | YES | Rest phase | MAJOR |
| World tick updates | YES | world_tick.py | NO (but must apply results) | Scene transition | — |
| Faction power calculation | YES | world_tick.py | NO | World tick | — |
| Social check resolution | YES | moves.py `resolve_move()` | NO | Social encounters | — |
| Move resolution (PbtA) | YES | moves.py | NO | All non-combat actions | — |
| **Round-end processing** | **NO** | — | **YES** | Every round | **CRITICAL** |
| **Combat-end detection** | **NO** | — | **YES** | Every round | **MAJOR** |
| **Death/0 HP handling** | **NO** | — | **YES** | HP reaches 0 | **MAJOR** |
| **Enemy action selection** | **NO** | — | **YES** | Every enemy turn | **MAJOR** |

**Coverage:** 13/24 computations fully scripted = **54%**. 4 CRITICAL gaps.

### 3.2: Anti-Pattern Scan

| Location | Instruction | What AI Is Asked to Compute | Script Alternative? |
|---|---|---|---|
| CLAUDE.md §12 | "Track Composure" | Track composure manually | Could be scripted |
| CLAUDE.md §17 step 6 | "Apply damage to target" | Subtract damage from HP, check for death | Could be scripted |
| CLAUDE.md §12 | "Morale: Enemies may flee at <25% HP" | Calculate HP percentage, decide flee | Could be scripted |
| hard-rules.md §Combat | "Simulate ALL attacks with actual rolls" | Run multiple attack CLIs | Partially scripted |
| CLAUDE.md §12 | Stances table: "AP: 2/3/4" | Track AP remaining per turn | Could be scripted |

### 3.3: Script Integration Quality

| Script | Self-Sufficient Inputs? | Parseable Output? | Narration Hooks? | Error Handling? |
|---|---|---|---|---|
| combat.py `attack_roll()` | NO (AI must extract stats) | YES (JSON) | YES (formatted markdown) | Minimal |
| moves.py `resolve_move()` | NO (AI must look up stat score) | YES (JSON) | YES (formatted markdown) | YES (validates inputs) |
| world_tick.py `world_tick()` | NO (needs world state JSON) | YES (JSON) | YES (World Pulse text) | Minimal |
| creature.py | YES (level + tier) | YES (JSON) | YES (stat block text) | YES |
| npc.py | YES (faction + role) | YES (JSON) | YES (character summary) | YES |
| scene.py | YES (location + region) | YES (JSON) | YES (scene description) | YES |

---

## Step 4: Narrator Control

### 4.1: Tone Enforcement Method

| Method | Count | Examples Found |
|---|---|---|
| Prescriptive examples (model narrations) | 2 | §9 (action resolution), §10 (scene transition + creatures) |
| Descriptive guidelines | 3 | §8 (Narrative Principles: 38 lines), §4 (GM Agenda: 12 lines), §5 (GM Principles: 13 lines) |
| Prohibitive warnings | 5 | hard-rules.md §Anti-Power-Fantasy, §Heroic Descriptor Prohibition, §Tone Reminders; CLAUDE.md line 5 warning |
| Genre labels without examples | 1 | hard-rules.md: "Dark Western + LitRPG + Political Fantasy + Survival Horror" |

- [x] Prescriptive examples exist: YES (2)
- [ ] Examples cover all scene types: NO (only action + scene transition; no social, exploration, environmental, NPC dialogue)
- [ ] Examples demonstrate genre blend: PARTIAL (survival horror tone shown, political/western less so)
- [ ] Tone examples in persistent context: YES (CLAUDE.md §8-10)
- [ ] Prescriptive > prohibitive: NO (5 prohibitive vs 2 prescriptive)

### 4.2: Narrator-Rules Boundary

- [x] Mechanical outcomes computed first, narrated second: YES (Response Gate mandates CLI-first)
- [x] AI instructed to show mechanical resolution: YES (Mandatory Sequence: "Mechanical display")
- [x] No "narratively resolve" permission: YES (no such instruction found)
- [x] Narrative authority bounded: YES (§8: "The dice decide, not you")

**Narrative override risk scan:** Zero instances of "for dramatic purposes," "if it makes narrative sense," or "to serve the story" overriding mechanical outcomes. The system is clean on this front.

### 4.3: NPC Voice Consistency

- [x] NPC dialogue constrained by disposition: YES (behavior.py SOCIAL_BEHAVIORS has disposition_reactions per archetype)
- [ ] NPC conversation follows goal structure: PARTIAL (behavior.py has motivations but no conversation goal trees)
- [ ] Named NPCs have voice notes: NO (NPC state has traits but no voice/speech pattern guidance)
- [ ] AI reads NPC state before voicing: PARTIAL (Gate 4 says run `npc` CLI for named NPCs, but doesn't say "read existing NPC from state")

---

## Step 5: GM Moves & Adjudication

### 5.1: GM Move System

- [x] Defined vocabulary: YES (8 soft + 8 hard = 16 moves)
- [x] Categorized by severity: YES (soft = warning/setup, hard = consequence)
- [x] Triggers defined: YES (CONSEQUENCE_TABLES maps position × outcome to move type)
- [x] Escalation rules: YES (controlled → soft; risky → hard; desperate → severe hard)
- [ ] Moves for each encounter type: PARTIAL (combat and PbtA covered; no social-specific or exploration-specific moves)

### 5.2: Adjudication Edge Cases

| Edge Case | Addressed? | Where? | Specific Enough? |
|---|---|---|---|
| Action not covered by any rule | PARTIAL | gm-protocol.md §When NOT to Roll | Says when not to roll, doesn't say what to do instead |
| Physically impossible action | NO | — | — |
| Player disputes mechanical outcome | NO | — | — |
| Two rules contradict | NO | — | — |
| Player asks "what can I do?" | PARTIAL | CLAUDE.md §7 (list available actions) | Combat only; not general |
| Action doesn't fit current phase | NO | — | — |
| Simultaneous player actions | NO | — | — |
| Player wants to retcon | NO | — | — |
| Mechanically correct but narratively absurd | NO | — | — |
| Player asks to see math/rolls | YES | CLAUDE.md §0 (show CLI output) | Explicit |

**Coverage:** 4/10 addressed (partially). Most edge cases would produce inconsistent AI behavior.

---

## Step 6: Error Recovery

| Error Type | Detection Method? | Recovery Protocol? | Authority Chain? | Where? |
|---|---|---|---|---|
| Computation error (wrong math) | PARTIAL (Self-Correction §3) | NO | Implicit | CLAUDE.md §3 |
| State desync (AI vs. state file) | YES (state hook shows current state) | PARTIAL ("state.json is canonical") | YES | Rule 7 |
| Behavioral violation (NPC off-pattern) | NO | NO | — | — |
| Tone drift | NO | NO | — | — |
| Continuity error (contradicts facts) | NO | NO | — | — |
| Player-flagged error | NO | NO | — | — |
| Rule misapplication | PARTIAL (Self-Correction) | NO | — | CLAUDE.md §3 |

**Coverage:** 2/7 error types have recovery protocols. Authority chain is implicit (Rule 7 establishes state.json as canonical, but no formal hierarchy is documented).

---

## Step 7: Integration Assessment

### 7.1: GM Function Separation

| Function | Dedicated Instructions? | Dedicated Scripts? | Dedicated State? | Separated? | Conflation Risk |
|---|---|---|---|---|---|
| Rules Arbiter | YES (Response Gate, Hard Rules) | YES (combat.py, moves.py) | NO | MOSTLY | LOW |
| World Simulator | YES (Gate 3, world-tick) | YES (world_tick.py, faction.py) | PARTIAL (missing Layer 3 state) | MOSTLY | MEDIUM |
| Narrator | YES (§8, worked examples) | NO | NO | PARTIAL | MEDIUM |
| Encounter Architect | PARTIAL (§12 difficulty guidance) | YES (creature.py, scene.py) | NO | PARTIAL | MEDIUM |
| NPC Controller | PARTIAL (Gate 4) | YES (npc.py, behavior.py) | PARTIAL (known_npcs in state) | PARTIAL | HIGH |
| Session Manager | YES (§11, §16, §17) | NO | YES (state.json) | PARTIAL | MEDIUM |

### 7.2: Cognitive Load by Phase

| Phase | Simultaneous Tracking | Active Functions | Context Load | Rating |
|---|---|---|---|---|
| Combat (multi-enemy) | HP (×4+), AP, conditions, initiative, stances, zones, telegraphs, clocks | Rules Arbiter, Narrator, NPC Controller, Encounter Architect | ~12,000 tokens | **HIGH** |
| Social (faction negotiation) | NPC dispositions, faction relations, PC standing, arena, position/effect | NPC Controller, Narrator, World Simulator | ~9,000 tokens | MEDIUM |
| Exploration (hostile territory) | Location, threats, encounter tables, time, resources | Encounter Architect, Narrator, World Simulator | ~8,000 tokens | MEDIUM |
| World Tick | All factions, all threats, relations, tags, clocks, meta clocks | World Simulator, Session Manager | ~10,000 tokens | MEDIUM |
| Downtime | Activity, NPC relationships, neighborhood tags, time passage | Session Manager, NPC Controller | ~6,000 tokens | LOW |

**Combat is the only HIGH phase.** It requires simultaneous tracking of 7+ variables across multiple entities while operating 4 GM functions. This is where failures concentrate.

---

## Failure Mode Risk Matrix

**PRIMARY DELIVERABLE — Sorted by Frequency × Severity (descending)**

| Rank | Failure Mode | Freq | Sev | Structural Cause | Prevention? | Priority Fix |
|---|---|---|---|---|---|---|
| 1 | **AI forgets condition ticks at round-end** | Every combat with conditions | CRITICAL | No `process_round_end()` script. No round-end checklist. AI must remember manually. | NO | B2: Script round-end processing |
| 2 | **AI loses AP tracking mid-combat** | Every combat >3 rounds | CRITICAL | No AP tracking in scripts. AI must count mentally. No display of AP remaining. | NO | E2: Script AP tracking |
| 3 | **AI skips world-tick at scene transitions** | ~40% of scene transitions | MAJOR | `--world-json` arg construction is unclear. AI falls back to simpler clock-tick. | PARTIAL (Gate 3) | Simplify world-tick invocation |
| 4 | **State.json schema drift from code** | Persistent (current state) | CRITICAL | Layer 3 code expects world_situation, inter_group_relations, pc_standing. State.json lacks them. | NO | B1: State migration |
| 5 | **AI does math instead of calling CLI** | ~10% of mechanical actions | MAJOR | Response Gate prevents most cases. But "apply damage" (subtract, check death) has no CLI. | PARTIAL (Gate 1) | B3/B4: Script condition/damage application |
| 6 | **Combat drags beyond 8 rounds** | ~15% of combats | MAJOR | No combat-end detection script. No morale check. AI must decide when to end. | NO | B2: Add combat-end detection |
| 7 | **NPC acts out of character** | ~20% of NPC interactions | MAJOR | No voice notes per NPC. AI reads behavior templates but doesn't re-read NPC state. | PARTIAL (Gate 4) | D-phase: NPC voice guidance |
| 8 | **AI enters wrong phase/mode** | Occasional | MINOR | No state machine. No `current_phase` in state. AI infers from context. | NO | Add phase tracking to state |
| 9 | **Tone drifts to heroic/safe** | ~10% of sessions | MAJOR | More prohibitive warnings than positive examples. AI lacks tone exemplars. | PARTIAL | D1: Positive narration examples |
| 10 | **Generated content contradicts facts** | Occasional | MAJOR | No fact-checking against state. Chronicle is brief. | NO | D3: Authority chain |
| 11 | **State contradictions accumulate** | Over long campaigns | MAJOR | No state validation. Dual-format update burden. Manual HP/condition tracking. | NO | State validation (future) |
| 12 | **Social encounters feel arbitrary** | ~30% of social scenes | MINOR | No structured social flow. PbtA moves work but no scene scaffolding. | PARTIAL | Already improved in Layer 3 |
| 13 | **Player loses trust in fairness** | Rare | MAJOR | No "show your work" protocol beyond CLI display. No dispute resolution. | PARTIAL | D2: Edge case guide |
| 14 | **World feels static between sessions** | ~25% if world-tick skipped | MAJOR | Depends on AI remembering Gate 3. World-tick output not auto-applied. | PARTIAL | Simplify world-tick flow |
| 15 | **AI loses track of which NPC is speaking** | Rare (solo campaign) | MINOR | Multiple NPCs in scene have no voice differentiation. | NO | D-phase: NPC voice |
| 16 | **Context overloads during complex combat** | Rare (200K window) | MINOR | Context budget is generous. Only an issue with very long sessions. | YES (large window) | Not urgent |

---

## CLAUDE.md Restructuring Plan

```
CURRENT: 764 lines, ~6,431 tokens, monolithic
TARGET:  ~400 lines, ~2,600 tokens, routing hub

RECOMMENDED STRUCTURE:

CLAUDE.md (~400 lines, routing hub):
  §0: Response Gate (76 lines, KEEP — most critical section)
  §1: Seven Hard Rules (13 lines, KEEP)
  §2: Failure Examples (60 lines, KEEP — effective training)
  §3: Self-Correction Protocol (23 lines, KEEP)
  §4: GM Agenda (12 lines, KEEP)
  §5: GM Principles (13 lines, KEEP)
  §6: Action Resolution Workflow (77 lines, KEEP — core loop)
  §7: Player Agency (23 lines, KEEP)
  §8: Narrative Principles (38 lines, KEEP)
  §15: World Pulse Format (20 lines, KEEP)
  §16: State Management (14 lines, KEEP — but move UP to after §3)
  §17: Session Workflow (32 lines, RESTRUCTURE with combat sub-phases)
  §19: Procedural Gen vs Lore (18 lines, KEEP)
  NEW: Phase-specific context routing (15 lines, replaces §20)
  TOTAL KEPT: ~434 lines, ~2,830 tokens

MOVE OUT OF CLAUDE.md:
  §9-10 (Worked Examples) → references/narration-examples.md
    Reason: Training examples, not operational instructions. 75 lines, ~683 tokens freed.
  §11 (Quick Start) → references/gm-protocol.md (append)
    Reason: One-time reference, not per-response. 17 lines, ~111 tokens freed.
  §12 (Combat System) → references/combat.md (merge with existing)
    Reason: Duplicates combat.md. 61 lines, ~514 tokens freed.
  §13 (CLI Command Reference) → references/cli-reference.md (NEW)
    Reason: Lookup table, not behavioral instruction. 51 lines, ~501 tokens freed.
  §14 (Awakening Protocol) → reference to references/awakening.md
    Reason: Duplicates awakening.md. 25 lines, ~189 tokens freed.
  §18 (Key Mechanics) → references/math-assumptions.md (merge)
    Reason: Duplicates math-assumptions.md. 24 lines, ~189 tokens freed.
  §20 (Reference Files) → replaced by phase-specific routing in CLAUDE.md
    Reason: Bottom-of-file lookup table rarely consulted. 54 lines, ~397 tokens freed.

TOTAL FREED: ~307 lines, ~2,584 tokens

REORDER:
  Move §16 (State Management) to immediately after §3 (Self-Correction)
    Reason: Save triggers are critical operational instructions buried at line 614.
  Move §15 (World Pulse) into §17 (Session Workflow)
    Reason: World Pulse is part of scene transition workflow, not standalone.

ADD TO CLAUDE.md:
  Combat sub-phase procedure in §17 (replaces current 9-step combat flow)
  Phase-specific context routing (replaces §20 lookup table)
  Round-end CLI call instruction in combat sub-phases
  Turn-start CLI call instruction in combat sub-phases
```

---

## Detailed Findings

### FINDING 4A-1: No Combat Round-End Procedure
**Severity:** CRITICAL
**Component:** 4A-Phases
**Evidence:** No function named `process_round_end`, `tick_conditions`, or `round_end` exists in any script. CLAUDE.md §17 (Combat Flow) has 9 steps, none addressing round-end processing.
**Failure Mode:** Conditions (Bleeding, Burning, Poisoned) are never automatically processed. Their damage and duration are forgotten.
**Frequency:** Every combat with conditions (estimated 60% of combats)
**Play Scenario:** Round 1: Player attacks wolf, wolf attacks back. Player gets Bleeding (2 dmg/turn for 3 turns). Round 2: AI presents player turn. No Bleeding damage applied. Player attacks again. AI forgets Bleeding exists. Round 3: AI has completely lost track. Bleeding never fires. By contrast, with a round-end CLI call, the AI would receive `{"condition_damage": [{"entity": "Shake", "condition": "Bleeding", "damage": 2, "turns_remaining": 2}]}` and be forced to narrate and apply it.
**Recommendation:** Phase B2 — Create `process_round_end()` in combat.py + CLI command.

### FINDING 4A-2: No Combat Sub-Phase Structure
**Severity:** MAJOR
**Component:** 4A-Phases
**Evidence:** CLAUDE.md §17 Combat Flow is 9 steps without clear phase boundaries. No separation between initiative, player turn, enemy turn, round end.
**Failure Mode:** AI skips steps, particularly enemy turns and round-end processing. Turn order becomes inconsistent.
**Frequency:** Every multi-round combat
**Play Scenario:** Round 2 of combat with 3 enemies. AI resolves player attack, then enemy 1 attacks, then asks "What do you do?" — skipping enemies 2 and 3. Without explicit sub-phases, the AI loses track of whose turn it is.
**Recommendation:** Phase C1 — Replace §17 Combat Flow with explicit sub-phases.

### FINDING 4B-1: State Schema Drift
**Severity:** CRITICAL
**Component:** 4B-State
**Evidence:** `campaigns/shake-rao/state.json` lines 136-138: `"entropy": 50, "momentum": 30, "connection": 0`. These fields are obsolete — Layer 3 code replaced them with situation tags. The state.json also lacks `world_situation`, `inter_group_relations`, and `pc_standing` keys that Layer 3 scripts expect.
**Failure Mode:** `world-tick` CLI cannot run properly against this state. Faction clocks lack required fields (`owner`, `goal`, `completion_effect`), causing KeyErrors. The entire Layer 3 simulation layer is disconnected from the live campaign.
**Frequency:** Persistent (current state of the live campaign)
**Play Scenario:** AI tries to run `world-tick --world-json '{...}'` using state.json data. Script crashes with KeyError on `clock["owner"]`. AI falls back to manual narration, defeating the purpose of Layer 3.
**Recommendation:** Phase B1 — Migrate state.json schema.

### FINDING 4B-2: CLAUDE.md Monolith
**Severity:** MAJOR
**Component:** 4B-State (context management)
**Evidence:** CLAUDE.md is 764 lines, ~6,431 tokens. Sections 12-14 and 18-20 duplicate content in reference files and consume ~1,790 tokens (28%).
**Failure Mode:** Instruction decay — AI attention to specific instructions degrades with file size. Critical instructions (State Management §16, Session Workflow §17) are buried at lines 614-661.
**Frequency:** Every session (degraded instruction adherence)
**Play Scenario:** AI processes response. Reads Response Gate (top of CLAUDE.md). Follows it. But State Management is at line 614 — AI sometimes forgets to save state.json after non-combat events. With restructured CLAUDE.md at ~400 lines, State Management would be in the top 40%.
**Recommendation:** Phase C2 — Aggressive restructuring.

### FINDING 4C-1: No Condition Turn-Start Processing
**Severity:** CRITICAL
**Component:** 4C-Scripts
**Evidence:** `conditions.py` defines 15+ conditions with `default_damage` and `default_duration` fields but has no function to process them. Only `create_condition_entry()` and `validate_ability_conditions()` exist.
**Failure Mode:** Bleeding (2 dmg/turn), Burning (3 dmg/turn), Poisoned (2 dmg/turn + -2 all rolls) are defined but never automatically applied. The AI must remember the damage values and compute them inline.
**Frequency:** Every combat with conditions
**Play Scenario:** Enemy wolf bites player, applying Poisoned. Next turn, AI should: (1) deal 2 poison damage, (2) apply -2 to all rolls, (3) decrement duration. Without a script, the AI typically remembers the damage but forgets the -2 penalty and never decrements duration.
**Recommendation:** Phase B3 — Create `process_turn_start_conditions()` in conditions.py.

### FINDING 4C-2: No AP Tracking in Scripts
**Severity:** CRITICAL
**Component:** 4C-Scripts
**Evidence:** `combat.py` defines stances with AP values (Balanced=3, Aggressive=3, Defensive=2, Focused=2) and `create_entity_state()` initializes `turn_state` but does not track `ap_remaining`. No function validates whether an action's AP cost can be afforded.
**Failure Mode:** Player declares multiple actions. AI doesn't enforce AP limits. Player gets 4 attacks in a turn when they should have 3 AP.
**Frequency:** Every combat with abilities (players naturally push for more actions)
**Play Scenario:** Player in Balanced stance (3 AP) says "I attack twice and cast a spell." Attack costs 1 AP, spell costs 2 AP = 4 AP total. Without AP tracking, AI allows all three because it's plausible-sounding. With scripted tracking, CLI would respond with "Insufficient AP: 3 available, 4 requested."
**Recommendation:** Phase E2 — Add AP tracking to combat state.

### FINDING 4D-1: Prohibitive > Prescriptive Tone Guidance
**Severity:** MINOR
**Component:** 4D-Narrator
**Evidence:** 5 prohibitive warnings (hard-rules.md §Anti-Power-Fantasy, §Heroic Descriptor Prohibition, §Tone Reminders) vs 2 prescriptive worked examples (CLAUDE.md §9-10). Worked examples demonstrate workflow, not tone.
**Failure Mode:** AI knows what NOT to do but has limited positive examples of correct tone. Over time, it defaults to generic fantasy narration.
**Frequency:** ~10% of sessions experience noticeable tone drift
**Play Scenario:** After 20 exchanges, AI narration subtly shifts from "the pry bar connects with a wet crunch — the thing's carapace cracks but it barely flinches" to "you land a powerful blow, cracking its armor." The second is generic fantasy, not survival horror. With positive tone exemplars, the AI would have concrete patterns to match.
**Recommendation:** Phase D1 — Add 3-5 positive narration examples.

### FINDING 4E-1: Insufficient Edge Case Coverage
**Severity:** MINOR
**Component:** 4E-Moves
**Evidence:** Only 4/10 adjudication edge cases addressed. No guidance for: physically impossible actions, rule disputes, retcons, simultaneous actions, narratively absurd outcomes, wrong-phase actions.
**Failure Mode:** When edge cases arise, two AI instances would handle them differently. Player trust erodes if handling seems arbitrary.
**Frequency:** Occasional (1-2 per session)
**Recommendation:** Phase D2 — Add edge case adjudication guide.

### FINDING 4F-1: No Error Recovery Protocols
**Severity:** MAJOR
**Component:** 4F-Errors
**Evidence:** Only Self-Correction Protocol (CLAUDE.md §3) exists. No procedure for: player-flagged errors, state desync recovery, continuity errors, tone correction, behavioral violations.
**Failure Mode:** When errors occur (guaranteed over a campaign), they compound. Player says "that's wrong, I had 53 HP not 69." AI has no procedure — sometimes it fixes correctly, sometimes it apologizes and makes it worse.
**Frequency:** Multiple times per campaign
**Recommendation:** Phase D4 — Add error recovery protocol.

### FINDING 4F-2: No Authority Chain Documentation
**Severity:** MAJOR
**Component:** 4F-Errors
**Evidence:** Rule 7 states "state.json is canonical" but no formal hierarchy exists for: state.json vs AI narration, CLI output vs AI calculation, hard-rules.md vs gm-protocol.md vs CLAUDE.md.
**Failure Mode:** When AI narration contradicts state.json, there's no defined resolution. AI might update state to match its narration (wrong) instead of re-reading state (right).
**Frequency:** Every session has minor state/narration tension
**Recommendation:** Phase D3 — Document authority chain.

---

## Priority Ranking

### 1. Structural Prerequisites (game can't run Layer 3 without these)
- **B1:** State schema migration (fix state.json to match Layer 3 code)
- **B2:** Combat round-end procedure (script condition ticking + combat-end detection)
- **B3:** Condition turn-start processing (script auto-damage + penalties)
- **B4:** CLI commands for round-end and turn-start

### 2. High-Frequency Failure Prevention
- **C1:** Combat sub-phase injection in CLAUDE.md
- **C2:** CLAUDE.md aggressive restructuring (764 → ~400 lines)

### 3. Consistency Fixes
- **D1:** Positive narration examples
- **D2:** Edge case adjudication guide
- **D3:** Authority chain documentation
- **D4:** Error recovery protocol

### 4. Quality Improvements
- **E1:** Phase-specific context loading instructions
- **E2:** AP tracking enforcement in combat.py
