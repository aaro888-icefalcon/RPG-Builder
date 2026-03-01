# Phase-Oriented Runtime Reorganization — Complete Implementation Guide

**Created:** 2026-02-16
**Status:** Planned — ready for implementation
**Scope:** `runtime/phases/` (new), minor updates to existing governance files and hooks

## Context

### Problem

The `runtime/` directory is organized by **domain** (references/, scripts/, tables/, lore/, assets/, tests/). The GM turn workflow is organized by **phase** (EXPLORATION, COMBAT, SOCIAL, DOWNTIME, SCENE_TRANSITION). When Claude enters a phase, it must mentally assemble context from across 4-6 domain directories — scanning monolithic reference files (400+ lines each) to find the relevant sections. Nothing in the file system groups content by phase.

This mismatch causes three concrete problems:
1. **Context waste**: Claude loads full reference files when it needs 20% of each
2. **Hook imprecision**: When hooks block, they point to generic CLAUDE.md sections instead of the specific skill/step that was violated
3. **Workflow fragility**: The turn protocol is spread across 6+ files; each new session must reconstruct the phase workflow from scratch

### Solution

Create `runtime/phases/` — a **phase-oriented navigation overlay** with one directory per GM turn phase. Each phase directory contains:
- `CLAUDE.md` — phase-specific operating instructions (auto-loaded when Claude reads into that directory)
- `index.md` — skill inventory and reference/hook map
- `skills/*.md` — one file per mechanical step, with exact CLI commands, canonical reference pointers, hook enforcement lists, and failure prevention tables

This is **strictly additive** — no existing files are moved, renamed, or deleted. The phase layer references canonical content in its existing locations.

### Outcome

- Claude can load exactly the right 200-300 lines of focused context per phase instead of scanning 1500+ lines across multiple files
- Hooks can point to specific skill files when they block (e.g., "See `phases/combat/skills/turn-start.md`" instead of "See CLAUDE.md §7")
- New sessions can pick up the phase workflow immediately from structured skill files
- The turn protocol becomes navigable by phase rather than reconstructed from first principles each time

---

## Architecture Rationale

### Why `runtime/phases/` (not `.claude/skills/`)

Design-principles.md §7 identifies `.claude/skills/` as a future surface for "reusable multi-step workflow templates." However:
- The `.claude/skills/` format is not yet used in this repo — adding it now would be a premature abstraction
- `runtime/phases/` is visible in the repo, reviewable in PRs, and follows the existing pattern where each domain directory has governance files
- Skill files in `runtime/phases/` serve both human navigation AND Claude context loading
- A promotion path to `.claude/skills/` exists when/if that format stabilizes

### Why overlay (not restructuring)

The Single Canonical Home principle (design-principles.md §3) means rules live in one place. Phase skill files REFERENCE rules in `references/`, never duplicate them. This eliminates the drift risk that comes with maintaining two copies.

The "Scripts stay where they execute" principle means Python files remain in `scripts/`. Phase directories point to CLI commands, never move them.

### Relationship model

```
Phase Skill File (e.g., combat/skills/attack-resolution.md)
    ├── REFERENCES → runtime/references/combat.md §Attack Resolution
    ├── REFERENCES → runtime/references/conditions.md
    ├── SCRIPTS ──→ runtime/scripts/emergence_cli.py attack
    ├── TABLES ───→ runtime/tables/encounter_context.py
    ├── ASSETS ───→ runtime/assets/current-scene-template.md
    └── HOOKS ────→ .claude/hooks/validate-combat-state.sh
```

No content duplication. Skill files contain instruction summaries + pointers.

---

## Complete Directory Layout

```
runtime/phases/                          # Phase-oriented navigation overlay
    CLAUDE.md                            # Phase system overview + detection table
    index.md                             # Phase inventory and router
    phase-manifest.md                    # Machine-readable: phase → hooks → CLI → refs

    exploration/
        CLAUDE.md                        # Exploration pre-response checklist
        index.md                         # Skill inventory + reference/hook map
        skills/
            scene-generation.md          # Run `scene` CLI, zone setup, atmosphere
            scene-pressure.md            # Mandatory free-narration pressure pulse
            perception-investigation.md  # `move` with reading_unknown arena
            terrain-navigation.md        # `move` with physical_striving/endurance
            scavenging-loot.md           # `loot` CLI, scarcity enforcement
            creature-preloading.md       # `creature`/`creatures` when threat within 2 rounds

    combat/
        CLAUDE.md                        # Combat pre-response checklist
        index.md                         # Skill inventory + reference/hook map
        skills/
            combat-setup.md              # PRE_COMBAT: enemy gen, initiative, zones
            turn-start.md               # `turn-start` CLI: condition ticking
            player-turn.md              # Display state, list actions, "What do you do?"
            attack-resolution.md         # `attack` CLI: hit band, damage, crits
            enemy-turn.md               # `evaluate-behavior` + `attack`: BINDING
            round-end.md                # `round-end` CLI: condition tick, expiry
            combat-exit.md              # Victory/defeat/flee, loot, transition

    social/
        CLAUDE.md                        # Social pre-response checklist
        index.md                         # Skill inventory + reference/hook map
        skills/
            npc-agenda-check.md          # `npc-agenda` CLI: escalation ladder
            arena-resolution.md          # 10 arenas + `move` CLI for social conflict
            relationship-update.md       # `relationship` CLI: NPC trust changes
            standing-update.md           # `pc-standing` CLI: faction rank/disposition
            diplomacy.md                # `diplomacy` CLI: inter-faction relations

    downtime/
        CLAUDE.md                        # Downtime pre-response checklist
        index.md                         # Skill inventory + reference/hook map
        skills/
            rest.md                     # Short/long rest mechanics, recovery formulas
            crafting.md                 # Crafting activities + move resolution
            training.md                 # Level-up, evolution, mentorship
            downtime-activities.md       # `downtime` CLI: general resolution

    scene-transition/
        CLAUDE.md                        # Scene transition pre-response checklist
        index.md                         # Skill inventory + reference/hook map
        skills/
            world-tick.md               # `world-tick` CLI: faction turns, threats
            clock-tick.md               # `clock-tick` CLI: advance clocks
            world-pulse.md              # World Pulse display format
            faction-update.md           # Interpret faction actions + portent events
            session-zero.md             # `session-zero` CLI: initial world state generation
            adventure-hook.md           # `adventure` CLI: adventure hooks from world state

    cross-cutting/
        CLAUDE.md                        # Always-applicable instructions
        index.md                         # Skill inventory
        skills/
            pre-turn-validation.md       # State validation, phase identification
            move-resolution.md           # Core PbtA move system (used all phases)
            forced-consequence.md        # v5.0 forced consequence system
            state-persistence.md         # State save, turn receipt, post-validation
            reference-freshness.md       # Pre-session freshness check
```

**Total new files: 48** (7 CLAUDE.md + 7 index.md + 33 skill files + 1 manifest)

---

## File Templates

### Template A: Phase CLAUDE.md

Every phase CLAUDE.md follows this exact structure. It must be **under 40 lines** (Map Not Manual principle). Example for combat:

```markdown
# Combat Phase — Operating Instructions

Scope: `runtime/phases/combat/`

## When Active

Combat is active when `state.json` has `.current_scene.combat_state.active == true`.

## Pre-Response Checklist

- [ ] Read state.json combat_state (entities, round, initiative, conditions)
- [ ] Identify whose turn it is
- [ ] Run `turn-start` CLI if conditions exist on current entity
- [ ] For player turns: display combat format, list actions, ask "What do you do?"
- [ ] For enemy turns: run `evaluate-behavior` CLI, narrate returned action EXACTLY
- [ ] At round boundaries: run `round-end` CLI

## Skills (load as needed)

| Skill | File | Trigger |
|-------|------|---------|
| Combat Setup | `skills/combat-setup.md` | Combat initiates |
| Turn Start | `skills/turn-start.md` | Any entity's turn begins |
| Player Turn | `skills/player-turn.md` | Player's turn in initiative |
| Attack Resolution | `skills/attack-resolution.md` | Any attack action |
| Enemy Turn | `skills/enemy-turn.md` | Enemy's turn in initiative |
| Round End | `skills/round-end.md` | All entities have acted |
| Combat Exit | `skills/combat-exit.md` | Combat concludes |

## CLI Commands

`turn-start`, `attack`, `roll`, `evaluate-behavior`, `round-end`, `creature`, `creatures`, `loot`

## Canonical References

- Combat system: `../../references/combat.md`
- Conditions: `../../references/conditions.md`
- Hard rules §8-12: `../../references/hard-rules.md`
- CLI reference: `../../references/cli-reference.md`

## Active Hooks

`validate-combat-state.sh`, `validate-combat-round-lifecycle.sh`, `validate-enemy-behavior.sh`,
`validate-forced-consequence.sh`, `validate-gm-response.sh`, `validate-narrative-principles.sh`,
`enforce-state-save.sh`
```

### Template B: Phase index.md

```markdown
# [Phase Name] — Content Inventory

## Skills

| Skill | File | CLI Commands | Trigger |
|-------|------|-------------|---------|
| [Name] | `skills/[file].md` | `[commands]` | [When it fires] |

## Canonical References

| Reference | Path | When Needed |
|-----------|------|-------------|
| [Topic] | `runtime/references/[file].md` | [Situation] |

## Active Hooks

| Hook | Enforcement |
|------|------------|
| `[hook-name].sh` | [What it checks] |

## Lore Connections (if applicable)

| Lore | Path | When Loaded |
|------|------|-------------|
| [Topic] | `runtime/lore/[file]` | [Trigger] |

## Tables Used (if applicable)

| Table | Path | Purpose |
|-------|------|---------|
| [Name] | `runtime/tables/[file].py` | [What it provides] |
```

### Template C: Skill File

Every skill file follows this exact structure:

```markdown
# Skill: [Name]

Phase: [PHASE_NAME]
Trigger: [One-sentence: when this skill activates]

## Summary

[2-5 sentences: what this skill does, why it matters, what the GM must NOT do]

## Prerequisites

- [State condition that must be true]
- [Resource/availability check]

## Steps

1. [Concrete step — include exact CLI command with all flags]
   ```bash
   python3 scripts/emergence_cli.py [subcommand] \
     --flag1 value --flag2 value
   ```
2. [Read specific field from CLI output]
3. [Apply result to state/narration]
4. [Display required output format]

## Canonical References

- [Topic]: `runtime/references/[file].md` §[Section heading]

## Scripts

- Primary: `runtime/scripts/emergence_cli.py [subcommand]`
- Module: `runtime/scripts/[module].py` ([function name])

## Hooks That Enforce This

- `[hook-name].sh` — [What it checks for this skill]

## Output Format

[Exact format block the GM must display after executing this skill]

## Common Failures

| Failure | Prevention |
|---------|-----------|
| [What goes wrong] | [How to prevent it] |
```

---

## Wave 1: Scaffolding (15 files)

### Purpose

Create the complete directory structure with all CLAUDE.md and index.md files. No skill files yet — this establishes the navigation framework.

### Files to create

**1. `runtime/phases/CLAUDE.md`**

Content: Phase system overview. Phase detection table mapping each phase to its state.json detection criteria and directory path. Relationship explanation (overlay, not relocation). Pointer to phase-manifest.md.

Key content elements:
- Phase detection table: EXPLORATION (no combat active, exploring), COMBAT (combat_state.active == true), SOCIAL (NPC interaction in progress), DOWNTIME (rest/craft/train), SCENE_TRANSITION (moving between scenes), CROSS-CUTTING (always)
- Relationship statement: "Phase directories contain ONLY navigation and instruction files. They REFERENCE canonical content in references/, scripts/, tables/, lore/, assets/"
- Pointer: "Machine-readable mapping: phase-manifest.md"

**2. `runtime/phases/index.md`**

Content: Phase inventory table with columns (Phase, Directory, Skill Count, CLI Commands). Navigation section with pointers to each phase CLAUDE.md and the manifest.

**3. `runtime/phases/phase-manifest.md`**

Content: Machine-readable mapping of each phase to its hooks, CLI commands, canonical references, and detection criteria. Format:

```markdown
# Phase Manifest

## EXPLORATION
- detection: state.json `.current_scene.scene_type` is "exploration" AND combat_state is null/inactive
- hooks: validate-gm-response, validate-forced-consequence, enforce-lore-loading, validate-narrative-principles, enforce-state-save, post-cli-reminder, inject-state-context, validate-state-write
- cli_commands: scene, scene-pressure, move, creature, creatures, loot
- references: hard-rules, gm-protocol, scarcity, enemies, equipment
- skills_dir: exploration/skills/

## COMBAT
- detection: state.json `.current_scene.combat_state.active == true`
- hooks: ALL (validate-gm-response, validate-combat-state, validate-combat-round-lifecycle, validate-enemy-behavior, validate-forced-consequence, validate-narrative-principles, enforce-state-save, post-cli-reminder, inject-state-context, validate-state-write)
- cli_commands: turn-start, attack, roll, evaluate-behavior, round-end, creature, creatures, move, loot
- references: hard-rules, gm-protocol, combat, conditions, mechanics
- skills_dir: combat/skills/

## SOCIAL
- detection: NPC interaction active (contextual — no single state flag)
- hooks: validate-gm-response, validate-forced-consequence, enforce-lore-loading, validate-narrative-principles, enforce-state-save, post-cli-reminder, inject-state-context, validate-state-write
- cli_commands: move, npc-agenda, relationship, pc-standing, diplomacy, npc, awakened-npc
- references: hard-rules, gm-protocol
- skills_dir: social/skills/

## DOWNTIME
- detection: Explicit downtime action declared or rest initiated
- hooks: validate-gm-response, validate-narrative-principles, enforce-state-save, post-cli-reminder, inject-state-context, validate-state-write
- cli_commands: downtime, move, relationship
- references: hard-rules, gm-protocol, scarcity, conditions
- skills_dir: downtime/skills/

## SCENE_TRANSITION
- detection: Scene change occurring (location change, significant time skip, phase boundary)
- hooks: validate-gm-response, validate-narrative-principles, enforce-state-save, post-cli-reminder, inject-state-context, validate-state-write
- cli_commands: world-tick, clock-tick, session-zero, adventure
- references: hard-rules, gm-protocol
- skills_dir: scene-transition/skills/

## CROSS_CUTTING
- detection: Always active — applies to all phases
- hooks: ALL
- cli_commands: validate-state, validate-turn-input, validate-turn-receipt, render-turn-narrative, move
- references: hard-rules, gm-protocol, cli-reference
- skills_dir: cross-cutting/skills/
```

**4-9. Phase CLAUDE.md files** (6 files, one per phase directory)

Each follows Template A above. Phase-specific content:

| Phase | Detection criteria | Key CLI commands | Most critical hooks |
|-------|-------------------|------------------|-------------------|
| exploration | No combat, exploring | scene, scene-pressure, move, creature/s | validate-gm-response, validate-forced-consequence |
| combat | combat_state.active == true | turn-start, attack, evaluate-behavior, round-end | validate-combat-state, validate-combat-round-lifecycle, validate-enemy-behavior |
| social | NPC interaction active | move (10 arenas), npc-agenda, relationship | validate-gm-response, validate-forced-consequence |
| downtime | Rest/craft/train declared | downtime, move, relationship | validate-gm-response, enforce-state-save |
| scene-transition | Scene change occurring | world-tick, clock-tick, session-zero, adventure | validate-gm-response, enforce-state-save |
| cross-cutting | Always | validate-state, validate-turn-input, move | ALL |

**10-15. Phase index.md files** (6 files, one per phase directory)

Each follows Template B above. Skill tables will be empty initially (just headers) and populated in Waves 2-4.

### Validation

- All directories exist
- All CLAUDE.md files are under 40 lines
- All referenced paths resolve to existing files
- `python runtime/tests/run_all_tests.py 1` passes
- `python runtime/scripts/validate_reference_freshness.py` passes

---

## Wave 2: Cross-Cutting + Combat Skills (12 files)

### Rationale

Cross-cutting skills (especially move-resolution) are used by every phase. Combat is the most hook-intensive phase with 4 combat-specific hooks. Doing both together means the highest-value skills are available first.

### Cross-Cutting Skills (5 files)

**`cross-cutting/skills/pre-turn-validation.md`**
- Trigger: Start of every turn
- Steps: Read state.json → validate-state CLI → identify phase from state → check reference freshness (first turn only)
- References: hard-rules.md §Pre-Response Checklist, runtime/CLAUDE.md §Truth Model
- Hooks: inject-state-context.sh, validate-state-write.sh

**`cross-cutting/skills/move-resolution.md`**
- Trigger: Player action with uncertain outcome AND real stakes
- Steps: (1) Select arena from 10 options, (2) set position [controlled/risky/desperate/deadly], (3) set effect [limited/standard/great], (4) run `move` CLI with stat-score, arena, action, threat-type, clocks-json, (5) read outcome tier [fumble/miss/partial/hit/crit], (6) execute forced consequence EXACTLY as returned — no substitution
- References: gm-protocol.md §Arenas, §Position/Effect, §Resolution Matrix; cli-reference.md §move
- Hooks: validate-forced-consequence.sh, validate-gm-response.sh (violation 1: CLI not run)
- CRITICAL: Include the full 10-arena table with primary stats, alt stats, and when-to-use guidance
- CRITICAL: Include the 4x4 resolution matrix (situation x outcome → consequence severity)

**`cross-cutting/skills/forced-consequence.md`**
- Trigger: Any move resolution that returns a forced_move
- Steps: (1) Read forced_move from CLI output, (2) identify type (hard/soft), category (threat/meta/narrative), and mechanical effect, (3) narrate the consequence EXACTLY, (4) apply mechanical effects (damage, condition, clock tick, environment change), (5) if meta-move (tick_clock, create_clock, new_threat_emerges, faction_move), execute the mechanical change
- References: cli-reference.md §Forced Consequence System, gm-protocol.md §Consequence Design
- Hooks: validate-forced-consequence.sh
- CRITICAL: List all threat types and their impulses (beast: to survive, swarm: to overwhelm, predator: to stalk and execute, humanoid_militant: to hold territory, etc.)

**`cross-cutting/skills/state-persistence.md`**
- Trigger: After every mechanics resolution
- Steps: (1) Identify all state changes (HP, conditions, clocks, NPCs, inventory, chronicle), (2) write changes to state.json, (3) run validate-state CLI, (4) if validation fails HALT, (5) write turn receipt to turn_receipts/, (6) run validate-turn-receipt CLI
- References: turn-loop.md §Steps 5-8, runtime/CLAUDE.md §Mandatory Turn Protocol
- Hooks: enforce-state-save.sh, validate-state-write.sh

**`cross-cutting/skills/reference-freshness.md`**
- Trigger: Start of each play session (first turn only)
- Steps: (1) Check each core runbook's "Last verified" commit against HEAD, (2) list: hard-rules.md, gm-protocol.md, cli-reference.md, combat.md, conditions.md, (3) if stale, note gap in docs/quality/reference-freshness.md
- References: hard-rules.md §Pre-Session Reference Freshness Check

### Combat Skills (7 files)

**`combat/skills/combat-setup.md`**
- Trigger: Combat initiates (threat appears, ambush, player attacks)
- Steps: (1) Run `creature` or `creatures` CLI for ALL enemies, (2) record initiative (from CLI output), (3) establish zone layout (from scene or custom), (4) display initial combat state in MANDATORY format, (5) determine first actor by initiative
- References: combat.md §Initiative, §Zone Combat; hard-rules.md §8-9
- Hooks: validate-combat-state.sh
- CRITICAL: Include the exact MANDATORY combat display format from CLAUDE.md §3

**`combat/skills/turn-start.md`**
- Trigger: Any entity's turn begins
- Steps: (1) Run `turn-start` CLI with entity's conditions, (2) apply auto-damage (Bleeding, Burning, Poisoned), (3) update HP before→after, (4) check for incapacitation/death, (5) display updated combat state
- References: combat.md §Turn Start, conditions.md §Auto-Damage conditions
- Hooks: validate-combat-round-lifecycle.sh
- CRITICAL: The turn-start CLI MUST run before any actions are taken. The hook enforces this.

**`combat/skills/player-turn.md`**
- Trigger: Player's turn in initiative order
- Steps: (1) Display full combat state (HP, Stamina, Mana, Composure, AP, RP, stance, conditions), (2) list ALL available actions with AP costs and technique tags, (3) list reaction options (Parry/Dodge/Intercept/OA), (4) end with "**What do you do?**", (5) STOP AND WAIT — do NOT resolve
- References: combat.md §Player Turn, §Available Actions; hard-rules.md §1-5 (player agency)
- Hooks: validate-combat-state.sh (format), validate-gm-response.sh (violation 2: missing prompt)
- CRITICAL: This skill is about PRESENTING options, not resolving them. Resolution happens in attack-resolution.md

**`combat/skills/attack-resolution.md`**
- Trigger: Player or NPC declares an attack
- Steps: (1) Verify AP cost, (2) run `attack` CLI with attacker stats, target stats, weapon, stance, (3) read hit_band (crit/exceptional/hit/graze/miss), (4) apply final_damage to target HP, (5) apply any conditions triggered by the attack, (6) check for death/incapacitation, (7) narrate the wound with anatomical specificity, (8) display updated combat state
- References: combat.md §Attack Resolution, §Hit Bands, §Called Shots; conditions.md
- Hooks: validate-combat-state.sh, validate-narrative-principles.sh
- Include: full hit band table with damage multipliers, crit threshold calculation

**`combat/skills/enemy-turn.md`**
- Trigger: Enemy's turn in initiative order
- Steps: (1) Run `evaluate-behavior` CLI with enemy's behavior rules and current combat state, (2) the returned action is BINDING — the GM MUST execute it, not override it, (3) run `attack` CLI if the behavior returns an attack, (4) display the enemy's action with telegraphing for next turn, (5) display "What the enemy will do next turn" preview
- References: combat.md §Enemy Behavior, §Telegraphing; cli-reference.md §evaluate-behavior
- Hooks: validate-enemy-behavior.sh (ensures evaluate-behavior was called)
- CRITICAL: "AI MUST execute returned action, not override" — this is a hard rule

**`combat/skills/round-end.md`**
- Trigger: All entities have acted in this round
- Steps: (1) Run `round-end` CLI, (2) tick all active conditions (reduce duration, apply end-of-round damage), (3) remove expired conditions, (4) check for combat end (all enemies dead, all players fled, etc.), (5) display round summary
- References: combat.md §Round End; conditions.md §Duration and Ticking
- Hooks: validate-combat-round-lifecycle.sh

**`combat/skills/combat-exit.md`**
- Trigger: Combat concludes (victory, defeat, flee, surrender)
- Steps: (1) Determine combat result, (2) award XP if applicable, (3) run `loot` CLI if enemies defeated (DEFAULT: no loot — hard-rules.md §22), (4) process Death's Harvest and other on-kill effects, (5) transition to exploration or scene-transition phase, (6) clear combat_state in state.json
- References: combat.md §Combat End; scarcity.md; hard-rules.md §22-23
- Hooks: enforce-state-save.sh

### Wave 2 Validation

- All 12 skill files follow Template C exactly
- All referenced canonical paths resolve (verify with grep/find)
- Update combat/index.md and cross-cutting/index.md with skill tables
- `python runtime/tests/run_all_tests.py 1` passes
- No content from references/ is duplicated — only referenced with §section pointers

---

## Wave 3: Exploration + Scene Transition Skills (12 files)

### Exploration Skills (6 files)

**`exploration/skills/scene-generation.md`**
- Trigger: Entering a new location or scene transition
- CLI: `emergence_cli.py scene --location "..." --region [type] --threat-level N --player-level N --scene-type exploration`
- Key output: zones (4, with properties/hazards/connections), objects (interactable, with DCs), atmosphere (sound/smell/sight), encounter_type
- References: gm-protocol.md §Scene Framing; cli-reference.md §scene
- IMPORTANT: Include the zone property glossary (Cover, Concealment, Difficult Terrain, High Ground, Elevation)

**`exploration/skills/scene-pressure.md`**
- Trigger: EVERY free narration turn where no dice roll was triggered
- CLI: `emergence_cli.py scene-pressure --world-json '<world state>' --scene-json '<scene state>'`
- Key output: tension_level, gm_moves (2-4, hard and soft), clock_ticks, new_content (NPCs, clocks), world_pulse_update
- References: gm-protocol.md §Scene Pressure; hard-rules.md §5 ("EXECUTE scene-pressure on EVERY free narration turn")
- CRITICAL: ALL returned GM moves MUST be narrated — no cherry-picking
- CRITICAL: This is the mechanism that prevents "quiet" turns — the engine always applies pressure

**`exploration/skills/perception-investigation.md`**
- Trigger: Player investigates, searches, tracks, diagnoses, or perceives
- Arena: reading_unknown (INT primary, WIS alt)
- Uses cross-cutting move-resolution skill
- Specific guidance: How to set position/effect for investigation moves, what "limited" vs "standard" vs "great" information looks like
- References: gm-protocol.md §Reading the Unknown arena

**`exploration/skills/terrain-navigation.md`**
- Trigger: Player traverses difficult/dangerous terrain, climbs, runs, jumps
- Arena: physical_striving (AGI primary, FOR alt) or endurance (FOR primary, WIL alt)
- Uses cross-cutting move-resolution skill
- Specific guidance: When to use physical_striving vs endurance, time cost of travel (hard-rules.md §Time Requirements)
- References: gm-protocol.md §Physical Striving, §Endurance; hard-rules.md §Time Requirements

**`exploration/skills/scavenging-loot.md`**
- Trigger: Player searches for supplies or post-combat loot
- CLI: `emergence_cli.py loot --level N --tier [common/uncommon/rare/boss]`
- DEFAULT IS NO LOOT (hard-rules.md §22: "Default to no loot")
- Skill Stone drop rate: 1% from standard monsters
- References: scarcity.md; hard-rules.md §22-23; equipment.md
- Hooks: validate-narrative-principles.sh (scarcity enforcement)

**`exploration/skills/creature-preloading.md`**
- Trigger: Threat detected within 2 rounds (hard-rules.md §9)
- CLI: `emergence_cli.py creature --level N --threat [minion/standard/elite/boss] --region [type] --time-of-day [dawn/day/dusk/night]`
- Or for groups: `emergence_cli.py creatures --level N --difficulty [easy/medium/hard/deadly] --region [type]`
- Key output: full stat block (HP, ATK, DMG, DEF, Init, Move, actions_per_turn), behavior rules (priority chain), abilities, encounter_context
- CRITICAL: Stats go in VISIBLE Enemies table, NOT hidden information
- References: hard-rules.md §8-9; enemies.md; combat.md §Enemy Stats
- Hooks: validate-gm-response.sh (violation 4: creature without CLI stats)

### Scene Transition Skills (6 files)

**`scene-transition/skills/world-tick.md`**
- Trigger: EVERY scene transition (hard-rules.md §26)
- CLI: `emergence_cli.py world-tick --days-elapsed N --current-day N --world-json '<full world state>'`
- Key output: faction_actions (each faction acts autonomously), relation_events, threat_actions, clock_ticks, tag_changes, world_pulse
- CRITICAL: Faction actions are AUTONOMOUS — they happen regardless of player
- CRITICAL: Portent events at clock thresholds are MANDATORY to narrate
- References: hard-rules.md §26-29; gm-protocol.md §World Tick
- Hooks: validate-gm-response.sh (violation 3: scene transition without clock-tick)

**`scene-transition/skills/clock-tick.md`**
- Trigger: Scene-pressure advancement, world-tick output, forced consequence, narrative event
- CLI: `emergence_cli.py clock-tick --clock "Name" --previous N --change N --max-value N --reason "..."`
- Key output: formatted tick display, completion status, reason
- CRITICAL: When a clock reaches its max, its completion_effect fires IMMEDIATELY
- CRITICAL: Check portent thresholds — if a portent fires, it MUST be narrated
- References: gm-protocol.md §Clock System

**`scene-transition/skills/world-pulse.md`**
- Trigger: Every scene transition, after world-tick completes
- No CLI — this is a display format skill
- Format: World Pulse block with News (rotate category), Rumors (quoted + source), Trends (situation + progress)
- News categories rotate: Faction / Local / Threat / Resource / Political / Wilderness / System
- References: hard-rules.md §303-315

**`scene-transition/skills/faction-update.md`**
- Trigger: After world-tick returns faction actions
- No additional CLI — interpret world-tick output
- Steps: (1) For each faction action, narrate what happened in the world, (2) update situation tags if world-tick changed them, (3) check inter-group relations for shifts, (4) check PC standing changes, (5) persist all changes to state.json
- References: hard-rules.md §26-34; gm-protocol.md §Faction Turn

**`scene-transition/skills/session-zero.md`**
- Trigger: Campaign initialization (runs once before the turn loop begins)
- CLI: `emergence_cli.py session-zero --human N --external N`
- Generates complete initial world state: factions (human + external threats), meta clocks, faction relationships, inter-group relations, PC standings, world situation context
- One-time command — not part of the recurring turn loop
- References: cli-reference.md §session-zero
- Hooks: None

**`scene-transition/skills/adventure-hook.md`**
- Trigger: Scene transition when new adventure content is needed
- CLI: `emergence_cli.py adventure --world-json '...' --location "..." --threat-level N --seed-type [conflict|rescue|heist|mystery|dilemma|clock|social] --depth [1|2|3]`
- Generates adventure hooks from world state; depth 1 = hook only, depth 2 = hook + scenes, depth 3 = full adventure with twist
- Pairs with world-tick output for integrated scene transitions
- References: cli-reference.md §adventure
- Hooks: None

### Wave 3 Validation

- Same as Wave 2: template compliance, path resolution, index updates, test suite

---

## Wave 4: Social + Downtime Skills (9 files)

### Social Skills (5 files)

**`social/skills/npc-agenda-check.md`**
- Trigger: Before any NPC social interaction
- CLI: `emergence_cli.py npc-agenda --archetype [type] --step N`
- Key output: current escalation step, behavior description, trigger for next step, `will_not_do` constraints
- Archetypes: authority/military → compliance; commune/faith → help; trade/criminal → asset; military/hunters → access control
- CRITICAL: `will_not_do` is BINDING — the GM cannot make NPCs do things on their refusal list
- CRITICAL: NPCs do NOT de-escalate unless PC addresses underlying need
- References: gm-protocol.md §NPC Escalation Ladders

**`social/skills/arena-resolution.md`**
- Trigger: Social conflict with uncertain outcome
- Uses cross-cutting move-resolution skill
- Specific content: The full 10-arena table with position/effect calibration guidance for SOCIAL arenas specifically:
  - honest_exchange: PRE primary, leverage spectrum for position
  - obligation: PRE primary, clarity of obligation for position
  - manipulation: PRE primary, target trust for position
  - implicit_violence: PRE primary, relative danger for position
  - explicit_threat: MIG primary, power advantage for position
- References: gm-protocol.md §Arenas (social subset)

**`social/skills/relationship-update.md`**
- Trigger: After significant NPC interaction (favor, betrayal, rescue, etc.)
- CLI: `emergence_cli.py relationship --npc-id "ID" --change N --reason "..."`
- Trust scale: 0 (hostile) → 6 (allied)
- Change amounts: favor (+1), rescue (+2), betrayal (-3)
- References: hard-rules.md §33-35

**`social/skills/standing-update.md`**
- Trigger: After significant faction interaction
- CLI: `emergence_cli.py pc-standing --faction-id "ID" --rank "new_rank" --disposition "new_disposition" --reason "..."`
- Rank scale: unknown → known → respected → trusted → inner_circle → leader
- Disposition: hostile → unfriendly → neutral → friendly → allied
- References: hard-rules.md §34

**`social/skills/diplomacy.md`**
- Trigger: Inter-faction relation change (trade agreement, war declaration, etc.)
- CLI: `emergence_cli.py diplomacy --faction-a "ID" --faction-b "ID" --relation "type" --reason "..."`
- Relation types: fealty / alliance / trade / neutral / tension / enmity / war
- References: hard-rules.md §33

### Downtime Skills (4 files)

**`downtime/skills/rest.md`**
- Trigger: Player declares short rest (1 hour) or long rest (8 hours)
- No specific CLI (resolved through move or auto-calculation)
- Short rest: Recover stamina (50%), no HP recovery without medical aid
- Long rest: Full HP/stamina/mana recovery, composure recovery (50% of missing)
- CONSTRAINT: Target 3 combats per long rest (hard-rules.md §20)
- References: combat.md §Rest, conditions.md §Recovery

**`downtime/skills/crafting.md`**
- Trigger: Player attempts to make/modify equipment
- Uses cross-cutting move-resolution skill (arena depends on craft type — physical_striving for physical crafting, system_magic for enchantment)
- DC guidelines: Simple repair DC 8, Improvised weapon DC 10, Quality weapon DC 14, Complex item DC 16
- References: equipment.md, scarcity.md

**`downtime/skills/training.md`**
- Trigger: Level-up, evolution selection, skill training
- For level-up: Use `character` CLI for stat changes
- For evolutions: Generate 5 options procedurally based on player's path (hard-rules.md §24-25)
- Teaching: 2+ days for 1 rank (hard-rules.md §Time Requirements)
- References: progression.md, evolutions-core.md, hard-rules.md §24-25

**`downtime/skills/downtime-activities.md`**
- Trigger: Player declares general downtime activity
- CLI: `emergence_cli.py downtime --activity "type" --duration "Xh/Xd" --character "name"`
- Activities: scavenge, repair, train, heal, socialize, investigate, build
- References: gm-protocol.md §Downtime

### Wave 4 Validation

- Same as previous waves

---

## Wave 5: Integration (modifications to existing files)

### 5.1: Add phase navigation to `runtime/CLAUDE.md`

Add a new section (3-5 lines) pointing to the phase system:

```markdown
## 8) Phase Navigation

Turn workflow is organized by phase in `phases/`. Load the relevant phase CLAUDE.md
for pre-response checklists and skill files:
- Phase overview and detection: `phases/CLAUDE.md`
- Phase manifest (hooks → CLI → references): `phases/phase-manifest.md`
```

Insert after the current §7 (Operational runbooks) section.

### 5.2: Update hook error messages

For each of the 11 hooks in `.claude/hooks/`, update the error message strings to reference the specific skill file instead of generic CLAUDE.md sections. **No logic changes — only string updates.**

| Hook | Current message points to | New message points to |
|------|--------------------------|----------------------|
| `validate-combat-state.sh` | `runtime/CLAUDE.md §3` | `runtime/phases/combat/skills/player-turn.md` |
| `validate-combat-round-lifecycle.sh` | `runtime/CLAUDE.md §7` | `runtime/phases/combat/skills/turn-start.md` and `round-end.md` |
| `validate-enemy-behavior.sh` | Generic | `runtime/phases/combat/skills/enemy-turn.md` |
| `validate-forced-consequence.sh` | Generic | `runtime/phases/cross-cutting/skills/forced-consequence.md` |
| `validate-gm-response.sh` violation 1 | `emergence_cli.py move` | `runtime/phases/cross-cutting/skills/move-resolution.md` |
| `validate-gm-response.sh` violation 3 | `emergence_cli.py clock-tick` | `runtime/phases/scene-transition/skills/clock-tick.md` |
| `validate-gm-response.sh` violation 4 | `emergence_cli.py creature` | `runtime/phases/exploration/skills/creature-preloading.md` |
| `validate-narrative-principles.sh` | Generic | `runtime/phases/cross-cutting/skills/forced-consequence.md` |

### 5.3: Update repo-maintenance-policy.md

Add to §1 (Placement rules):

```markdown
4. Phase navigation overlays belong in `phases/*`:
   - Phase CLAUDE.md: operating instructions (< 40 lines)
   - Phase index.md: skill inventory and reference map
   - Phase skills/*.md: instruction files that REFERENCE canonical sources
   - NEVER duplicate canonical content in skill files — reference with §section pointers
```

Add to §3 (Structural PR checklist):

```markdown
- [ ] Phase skill files reference canonical sources, not duplicate them.
- [ ] Phase CLAUDE.md files are under 40 lines.
- [ ] New skills placed in correct phase directory (or cross-cutting if multi-phase).
```

### Wave 5 Validation

- Full test suite: `python runtime/tests/run_all_tests.py 1`
- Reference freshness: `python runtime/scripts/validate_reference_freshness.py`
- Verify all paths in all 33 skill files resolve to existing files
- Verify no hook logic changes (only string changes in error messages)
- Verify `runtime/CLAUDE.md` stays within reasonable size (< 150 lines total)

---

## Governance & Schema Guidance for Going Forward

These rules should be persisted in the development documents (repo-maintenance-policy.md, design-principles.md) so that all future edits stay within the organized framework.

### Rule 1: Phase-First Placement for New Skills

When adding a new mechanical step or workflow to the GM turn:
1. Identify which phase it belongs to (exploration, combat, social, downtime, scene-transition, cross-cutting)
2. Create a skill file in that phase's `skills/` directory following Template C
3. Update the phase's `index.md` with the new skill
4. Update `phase-manifest.md` if the skill introduces new CLI commands or hook requirements
5. If the skill applies to multiple phases, place it in `cross-cutting/`

### Rule 2: Reference-Not-Duplicate

Skill files must NEVER contain:
- Copy-pasted rule text from `references/` files
- Re-stated CLI parameter documentation from `cli-reference.md`
- Duplicated stat formulas or damage tables

Instead, use §section pointers:
```markdown
- Attack resolution bands: `runtime/references/combat.md` §Attack Resolution
```

If a referenced section doesn't have a clear heading to point to, that's a signal to add one to the canonical file — not to copy the content into the skill file.

### Rule 3: CLAUDE.md Size Budget

Phase CLAUDE.md files: **40 lines max**
Root runtime CLAUDE.md: **150 lines max**

If a CLAUDE.md grows beyond its budget, the excess belongs in:
- A new skill file (if it's a procedural instruction)
- A referenced document (if it's a rule or policy)
- The index.md (if it's inventory/navigation content)

### Rule 4: Skill File Completeness Contract

Every skill file MUST include all sections from Template C:
- Summary (what + why + what NOT to do)
- Prerequisites (state conditions)
- Steps (exact CLI commands with flags)
- Canonical References (§section pointers)
- Scripts (CLI subcommand + backing module)
- Hooks That Enforce This (which hooks validate this skill)
- Output Format (what the GM must display)
- Common Failures (prevention table)

If a section genuinely doesn't apply (e.g., "Hooks" for a pure display skill), include the heading with "None" rather than omitting it.

### Rule 5: Hook-Skill Alignment

When adding or modifying a hook:
1. Identify which skill(s) the hook enforces
2. Update the skill file's "Hooks That Enforce This" section
3. Update the hook's error message to point to the specific skill file
4. Update `phase-manifest.md` with the hook-to-phase mapping

When a hook blocks and the error message says "See `phases/combat/skills/turn-start.md`", the blocked session can load that specific file to understand exactly what it needs to do differently.

### Rule 6: Phase Manifest as Single Source of Phase-to-Hook Mapping

`phase-manifest.md` is the canonical mapping of:
- Phase → detection criteria
- Phase → active hooks
- Phase → CLI commands
- Phase → canonical references
- Phase → skills directory

Any time a new hook is added, a new CLI command is created, or a reference file is added/renamed, the manifest MUST be updated in the same PR.

### Rule 7: Skill Promotion Path

If a skill file proves so valuable that it should be loaded automatically (rather than on-demand), it can be promoted to `.claude/skills/` when that surface is activated. The promotion path:
1. Skill has been used 3+ times across sessions (design-principles.md §7 threshold)
2. Create a `.claude/skills/` entry that mirrors the markdown content
3. Keep the `runtime/phases/` skill file as the human-readable documentation
4. The `.claude/skills/` entry becomes the machine-loaded version

This promotion is NOT part of the current plan — it's guidance for when the `.claude/skills/` surface is eventually activated.

---

## Appendix A: What Does NOT Change

| Directory/File | Why unchanged |
|---|---|
| `runtime/references/*` (30+ files) | Single Canonical Home — phase skills reference, never duplicate |
| `runtime/scripts/*` (23 modules) | Scripts stay where they execute |
| `runtime/tables/*` (10 modules) | Data tables consumed by scripts — no phase coupling |
| `runtime/lore/*` (all files) | World content — loaded situationally by hooks |
| `runtime/assets/*` (templates) | Templates — no phase coupling |
| `runtime/tests/*` (35+ tests) | Validation suite — no phase coupling |
| `runtime/docs/workflows/*` | turn-loop.md, play-runbook.md remain canonical |
| `runtime/docs/scripts/index.md` | Script registry stays canonical |
| `runtime/state.json` | Canonical state — never structural changes during this work |
| `.claude/settings.json` | Hook registration — unchanged |
| `.claude/hooks/*.sh` (logic) | Hook detection logic — unchanged; only error message strings updated |

---

## Appendix B: Critical File Paths for Implementation

### Files to READ before writing skill content (canonical truth sources)

| File | Used by skills in |
|------|------------------|
| `runtime/references/hard-rules.md` | ALL — the master rule set |
| `runtime/references/gm-protocol.md` | social, exploration, cross-cutting — arenas, consequences, world tick |
| `runtime/references/combat.md` | combat — attack resolution, turn lifecycle, combat display |
| `runtime/references/conditions.md` | combat, downtime — condition mechanics, composure |
| `runtime/references/cli-reference.md` | ALL — CLI command documentation |
| `runtime/references/scarcity.md` | exploration, downtime — loot rules, resource economy |
| `runtime/references/enemies.md` | exploration, combat — creature generation context |
| `runtime/references/equipment.md` | exploration, combat, downtime — weapon/armor stats |
| `runtime/references/mechanics.md` | cross-cutting — core math (crit range, stat modifiers) |
| `runtime/references/progression.md` | downtime — level-up, evolution |
| `runtime/references/evolutions-core.md` | downtime — evolution options |
| `runtime/CLAUDE.md` | combat — §3 combat display format, §7 combat protocol; cross-cutting — §Truth Model, §Mandatory Turn Protocol |
| `runtime/docs/workflows/turn-loop.md` | cross-cutting — 8-stage turn protocol |
| `runtime/docs/scripts/index.md` | ALL — CLI command registry |

### Files to MODIFY (Wave 5 only)

| File | Change |
|------|--------|
| `runtime/CLAUDE.md` | Add §8 Phase Navigation (3-5 lines) |
| `development/repo-maintenance-policy.md` | Add phase-related placement and PR checklist items |
| `.claude/hooks/validate-gm-response.sh` | Update 4 error message strings |
| `.claude/hooks/validate-combat-state.sh` | Update 1 error message string |
| `.claude/hooks/validate-combat-round-lifecycle.sh` | Update 1 error message string |
| `.claude/hooks/validate-enemy-behavior.sh` | Update 1 error message string |
| `.claude/hooks/validate-forced-consequence.sh` | Update 1 error message string |
| `.claude/hooks/validate-narrative-principles.sh` | Update 1 error message string |
| `.claude/hooks/enforce-state-save.sh` | Update 1 error message string |

---

## Appendix C: Verification Checklist (Run After All Waves)

```bash
# 1. Test suite
python runtime/tests/run_all_tests.py 1

# 2. Reference freshness
python runtime/scripts/validate_reference_freshness.py

# 3. Verify all phase directories exist
ls -la runtime/phases/*/CLAUDE.md
ls -la runtime/phases/*/index.md
ls -la runtime/phases/*/skills/*.md

# 4. Count files (should be 48)
find runtime/phases/ -type f | wc -l

# 5. Verify no content duplication (skill files should reference, not copy)
# Search for multi-line blocks that appear in both references/ and phases/
# This is a manual check — look for copy-pasted paragraphs

# 6. Verify CLAUDE.md size limits
wc -l runtime/phases/*/CLAUDE.md  # Each should be < 40 lines
wc -l runtime/CLAUDE.md            # Should be < 150 lines

# 7. Verify hook changes are string-only (no logic changes)
git diff .claude/hooks/ | grep -c "^[+-].*if\|^[+-].*then\|^[+-].*fi\|^[+-].*exit"
# Should be 0 — no logic changes

# 8. State validation still works
python runtime/scripts/validate_state.py runtime/state.json
```
