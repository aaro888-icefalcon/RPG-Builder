# Execution Plan: Starting Situation Stabilization

- **Owner:** Development
- **Status:** Draft
- **Start Date:** 2026-02-23
- **Target Date:** Rolling (phased delivery — see PR schedule below)
- **Related Decision Logs:** None yet

## Objective

Stabilize the game's starting situation by:
1. Implementing a System status screen at game start where the player explicitly **chooses** archetype, aspect, and starting form
2. The System assesses every human and assigns a standardized attribute array; aspect and archetype bonuses then layer on top
3. Adding a `new-game` CLI command that wraps the full setup flow
4. Expanding the transported geography to include the greater NYC metro area (~14.5M)
5. Establishing that civil authorities remain but are pressed (not absent)
6. Setting the casualty model: heavy losses in the first month but the majority survive

## Scope

### In scope
- Character creation flow (status screen, explicit choice model)
- Disposition of `awakening.md` (rewrite to align with status screen; deprecate narrative-first-combat model)
- System-assessed standard array with aspect/archetype bonuses on top
- New `new-game` CLI command (wraps session-zero + character + game-start)
- Changes to existing CLI commands (`character`, `session-zero`, `game-start`)
- Geographic expansion (lore, setting, geography, locations, faction/neighborhood files)
- World situation tags (civil authority present but strained)
- Population figures across all references
- State.json initial state (chronicle, world_situation, campaign references)
- New-game-setup skill (updated flow)
- All 7 integration touchpoints per change-integration-checklist §2

### Out of scope
- State schema structural changes (new CLI output fields like `base_array` are transient — not persisted to state.json character block)
- Combat mechanics, form mechanics, class mechanics (unchanged)
- External faction lore (Vaelithar indigenous powers unchanged)
- Existing CLI validation scripts (validate_state.py, etc. — no structural changes, but will be run)
- Directory renaming (`factions-nyc/` keeps its name; expanded scope noted in file headers)
- `no_central_authority` encounter modifier gap (pre-existing; out of scope for this plan)

### Scope accounting (§3 surfaces touched)

This plan touches 5 major surfaces, which **exceeds the 2-surface split threshold**. It is therefore split into 3 phased PRs:

| PR | Surfaces | Content |
|---|---|---|
| **PR-A: Lore & World Situation** | Phase 1 lore references, Phase 3 world-building tables, State data | Geography, population, factions, casualties, civil authority lore, `state.json` tag/text updates, `world_situation.py` tag additions + neighborhood expansion |
| **PR-B: Character Creation & Awakening** | Phase references (mechanics), Phase skills | Status screen flow in `creation.md`, `awakening.md` rewrite, `aspects-archetypes.md` status summaries, `new-game-setup.md` skill update (status screen docs + forthcoming `new-game` noted) |
| **PR-C: CLI Implementation** | Phase scripts, Phase manifest | `character.py` standard array, `emergence_cli.py` changes (`character`, `new-game`, region choices), `scene.py` terrain additions, `new-game-setup.md` CLI invocation promotion, `world_situation.py` encounter modifiers, script registry, phase-manifest, cli-reference, tests |

Each PR is independently shippable. PR-B and PR-C depend on PR-A for consistent lore references. PR-C depends on PR-B for consistent creation flow documentation.

**Independent shippability constraint:** PR-B documents the status screen flow but does not promote `new-game` to primary invocation in `new-game-setup.md` — that step occurs in PR-C after the CLI exists. Between PR-B and PR-C ships, the 3-step manual sequence (session-zero → character → game-start) remains the active working path.

---

## Milestones

1. **PR-A merged** — All lore, world situation tags, and state.json data consistent with metro area scope and `civil_authority_strained` Day 1 default
2. **PR-B merged** — All character creation docs reflect status screen model; `awakening.md` no longer contradicts `creation.md`; `new-game-setup.md` documents the status screen flow with forthcoming `new-game` CLI noted
3. **PR-C merged** — `new-game` CLI operational; all touchpoints wired; full test suite passes; `new-game-setup.md` promotes `new-game` to primary invocation

---

## Design Decisions

### D1: Status Screen Character Creation

Replace the current narrative-awakening flow with an explicit **System status screen**. At game start, after the Transit, the System presents:

1. **Status screen appears** — The System runs its "biological assessment" and presents options
2. **Choose Archetype** (1 of 8) — Framed as "crisis response profile detected"
3. **Choose Aspect** (1 of 8) — Framed as "elemental resonance identified"
4. **Class auto-derived** — Aspect x Archetype grid (unchanged)
5. **Choose starting Form** (1 from derived pool) — Framed as "initial capability unlocked"
6. **Background** remains GM-assigned (pre-Transit profession, determines +2/+1 stat targets)

The narrative framing: The System *scans* everyone during Transit and presents choices based on latent potential. The player doesn't roleplay into their class — they select it from a menu.

**Status Screen Template:**
```
╔═══════════════════════════════════════════════════════════════════╗
║  BIOLOGICAL ASSESSMENT COMPLETE                                   ║
║                                                                   ║
║  BACKGROUND DETECTED: [profession]                                ║
║  BASELINE ATTRIBUTES: CALIBRATED                                  ║
║                                                                   ║
║  CRISIS RESPONSE PROFILE — SELECT ARCHETYPE:                      ║
║                                                                   ║
║  [1] STRIKER     — You attacked the threat directly               ║
║  [2] GUARDIAN    — You shielded others from harm                  ║
║  [3] HUNTER      — You found high ground and assessed             ║
║  [4] SKIRMISHER  — You kept moving, struck fast                   ║
║  [5] MENDER      — You tended to the wounded                      ║
║  [6] WARDEN      — You controlled the situation                   ║
║  [7] ANALYST     — You figured out what was happening             ║
║  [8] SPEAKER     — You rallied and organized people               ║
║                                                                   ║
╚═══════════════════════════════════════════════════════════════════╝
```

After archetype selection, a second screen presents aspect choices, then class is auto-derived, then form pool is shown for selection.

**Disposition of awakening.md:** The current `awakening.md` defines a narrative-first-combat flow that contradicts the status screen model. It will be **rewritten** (not deleted) to:
- Remove the "fight first, then choose" Phase 2 first-crisis protocol
- Retain the System display templates (INTEGRATION PENDING → AWAKENING COMPLETE) with updated content
- Redirect to `creation.md` for the actual choice flow
- Keep the class grid reference (shared with creation.md)
- Remove pre-awakening combat rules (no longer applicable)
- Update phase-manifest.md to reflect the changed scope of `awakening`

### D2: System-Assessed Standard Array + Aspect/Archetype Bonuses

The System performs a **biological assessment** during Transit. It evaluates each human and assigns a standardized baseline attribute array. Aspect and archetype bonuses then layer on top to create final starting stats.

**Step 1 — System Assessment (baseline):**

The System assigns every human the same standard array, distributed across stats based on the character's background (pre-Transit life, physical condition, mental aptitude). The GM assigns the array values to stats based on the character's description.

**Standard Array:** `[8, 9, 9, 10, 10, 11, 11, 12]` (average: 10.0)

The GM places these 8 values across the 8 attributes based on who the character was before the Transit. A construction foreman puts the 12 in FOR or MIG. A surgeon puts the 12 in PRC or INT. A politician puts the 12 in PRE. This is the System's reading of the person's pre-existing biology and conditioning — it has nothing to do with aspect or archetype yet.

**Implementation note:** In `character.py`, the array constant is stored highest-to-lowest as `STANDARD_ARRAY = [12, 11, 11, 10, 10, 9, 9, 8]` and zipped with the `--stat-order` argument list (first stat gets 12, second gets 11, etc.).

**Step 2 — Aspect Bonuses (elemental resonance):**

After the player selects their aspect, the System applies:
- +2 to aspect primary stat
- +1 to aspect secondary stat

| Aspect | Primary (+2) | Secondary (+1) |
|--------|-------------|----------------|
| Ore | Fortitude | Might |
| Tide | Precision | Agility |
| Pyre | Might | Willpower |
| Gale | Agility | Precision |
| Radiance | Presence | Wisdom |
| Shroud | Willpower | Intellect |
| Anima | Wisdom | Fortitude |
| Aether | Intellect | Willpower |

**Step 3 — Archetype Bonuses (crisis response awakening):**

After the player selects their archetype, the System applies:
- +2 to archetype primary stat
- +1 to archetype secondary stat

| Archetype | Primary (+2) | Secondary (+1) |
|-----------|-------------|----------------|
| Striker | Might | Fortitude |
| Guardian | Fortitude | Willpower |
| Hunter | Precision | Agility |
| Skirmisher | Agility | Precision |
| Mender | Wisdom | Willpower |
| Warden | Willpower | Wisdom |
| Analyst | Intellect | Wisdom |
| Speaker | Presence | Intellect |

**Step 4 — Background Bonuses (GM-assigned, unchanged):**

- +2 to one stat based on pre-Transit profession
- +1 to another stat based on pre-Transit profession

**Final stat range:** 8 (array low, no bonuses) to 18 (array 12 + aspect +2 + archetype +2 + background +2). Typical spread: 8-15, with most stats in 9-13.

**Example: Marcus Chen — Construction Foreman, Ore × Guardian**

GM assigns array based on description: physically powerful foreman, tough, not particularly quick or charismatic.

| Stat | Array (System) | Aspect (Ore) | Archetype (Guardian) | Background (Physical) | Final |
|------|---------------|-------------|---------------------|----------------------|-------|
| MIG | 11 | +1 (secondary) | — | +1 | **13** |
| AGI | 9 | — | — | — | **9** |
| FOR | 12 | +2 (primary) | +2 (primary) | +2 | **18** |
| PRC | 9 | — | — | — | **9** |
| INT | 8 | — | — | — | **8** |
| WIS | 10 | — | — | — | **10** |
| WIL | 10 | — | +1 (secondary) | — | **11** |
| PRE | 11 | — | — | — | **11** |

**Example: Priya Sharma — ER Nurse, Radiance × Mender**

GM assigns array: empathetic, perceptive, calm under pressure, not physically imposing.

| Stat | Array (System) | Aspect (Radiance) | Archetype (Mender) | Background (Medical) | Final |
|------|---------------|-------------------|-------------------|---------------------|-------|
| MIG | 8 | — | — | — | **8** |
| AGI | 9 | — | — | — | **9** |
| FOR | 9 | — | — | — | **9** |
| PRC | 10 | — | — | — | **10** |
| INT | 11 | — | — | +2 | **13** |
| WIS | 11 | +1 (secondary) | +2 (primary) | +1 | **15** |
| WIL | 10 | — | +1 (secondary) | — | **11** |
| PRE | 12 | +2 (primary) | — | — | **14** |

**Why this model?** The System assesses your baseline biology (the array). Then your choices — which elemental force resonates with you (aspect) and how you respond to crisis (archetype) — add power on top. The array is who you were; the bonuses are who you're becoming.

### D3: New `new-game` CLI Command

A new unified CLI command that wraps the complete campaign initialization:

```bash
python3 emergence_cli.py new-game \
  --aspect gale \
  --archetype skirmisher \
  --background-type criminal \
  --background-primary agility \
  --background-secondary precision \
  --stat-order "agility,precision,fortitude,might,willpower,intellect,wisdom,presence" \
  --starting-form "Dual Wield" \
  --location "Midtown Manhattan" \
  --region urban \
  --human-factions 10 \
  --external-threats 10 \
  --seed 42
```

**Arguments:**

| Argument | Required | Default | Description |
|----------|----------|---------|-------------|
| `--aspect` | Yes | — | One of 8 aspects |
| `--archetype` | Yes | — | One of 8 archetypes |
| `--background-type` | Yes | — | Background category (physical, combat, medical, technical, social, survival, criminal, academic, religious, artistic) |
| `--background-primary` | Yes | — | Stat receiving +2 from background |
| `--background-secondary` | Yes | — | Stat receiving +1 from background |
| `--stat-order` | Yes | — | Comma-separated stat names, highest-to-lowest array assignment (12 → first stat, 11 → second, etc.) |
| `--starting-form` | No | Auto (first in pool) | Form name from derived pool |
| `--location` | No | "Midtown Manhattan" | Starting location name |
| `--region` | No | "urban" | Starting region type |
| `--threat-level` | No | 2 | Starting area threat level |
| `--human-factions` | No | 10 | Number of human factions |
| `--external-threats` | No | 10 | Number of external threats |
| `--seed` | No | Random | RNG seed for reproducibility |

**Output:** Complete JSON suitable for direct persistence as `state.json`, including:
- Full world state from session-zero (factions, threats, clocks, relations, world_situation)
- Character block with System-assessed array + bonuses, derived values, form slot
- Opening scene (current_scene)
- Campaign metadata (day 1, time 14:47, population 14.5M)
- World pulse (Day 1 news)
- Initial chronicle entry

**Clarification — transient vs. persisted fields:** The `base_array` and `bonuses_applied` fields appear in CLI stdout for debugging/verification but are **not** written into the `state.json` character block. The persisted character block contains only `attributes` (final values), consistent with the existing schema. No state schema changes are required.

**Relationship to `game-start`:** The `game-start` command is **retained** as a standalone tool for scene generation in ongoing campaigns — e.g., generating a new scene at session start, or recovering/rebuilding a scene after state corruption. `new-game` uses `generate_scene()` internally rather than calling `game-start` as a subprocess. They are complementary: `new-game` is for Day 1 initialization only; `game-start` handles all subsequent scene generation.

**Internal flow:**
1. Set RNG seed
2. Call `generate_session_zero_factions()` → world state
3. Assign standard array to stats per `--stat-order` → base stats
4. Apply aspect, archetype, and background bonuses → final stats
5. Calculate derived stats → full character block
6. Call `generate_scene()` → opening scene
7. Assemble complete state.json structure
8. Output JSON (persisted fields only; diagnostic breakdown to stderr)

### D4: Expanded Geography

**Transported areas and populations (real-world 2024 estimates):**

| Area | Population | Notes |
|------|-----------|-------|
| Manhattan | 1.6M | Urban core, financial district |
| Brooklyn | 2.6M | Eastern borough, fragmented neighborhoods |
| Queens | 2.3M | Eastern borough, isolated enclaves |
| The Bronx | 1.4M | Northern borough, Thornwood frontier |
| Staten Island | 0.5M | Southern borough, cut off |
| Hudson County NJ (Hoboken, Jersey City, Bayonne) | 0.7M | Western shore, industrial waterfront |
| Bergen County NJ (southern portion) | 0.5M | Northwestern suburban |
| Nassau County (Long Island) | 1.4M | Eastern suburban, dense |
| Suffolk County (Long Island) | 1.5M | Far eastern, mix suburban/rural |
| Westchester County | 1.0M | Northern suburban, wealthy towns |
| Rockland County | 0.3M | Northwestern, across Hudson |
| Fairfield County CT (southern portion) | 0.6M | Northeastern, I-95 corridor |
| **Total** | **~14.4M** | Round to **~14.5M** |

**Geographic footprint:** Roughly 60 miles east-west (Suffolk to Bergen) by 40 miles north-south (Fairfield to Staten Island). A substantial land mass.

**Impact on zone system:** The "city edge" is no longer a single ring. Instead:
- **Urban core** (Manhattan, inner Brooklyn/Queens, Jersey City) — dense, faction-controlled
- **Inner suburban** (outer boroughs, Hoboken, Nassau, Yonkers) — mixed control, some order
- **Outer suburban** (Suffolk, northern Westchester, Rockland, Fairfield, Bergen) — thin authority, creature pressure at edges
- **The Verge** (boundary where transported land meets Vaelithar) — same concept as current but much larger perimeter (~200 mile circumference)

**Impact on geography.md cardinal directions:** The existing cardinal direction references (Thornwood 3mi north, etc.) measured from "city edge." With the metro expansion, distances from the **metro edge** will vary by direction. Northern edge (Fairfield/Westchester) is closer to Thornwood. Eastern edge (Suffolk) is closer to Crystalveld. The geography.md rewrite must specify distances from the nearest metro edge, not from Manhattan center.

**Directory naming:** The `factions-nyc/` directory retains its name for stability. File headers within are updated to note "Metro Area" scope. Phase 1 `index.md` description for `locations.md` is updated from "Named locations in NYC" to "Named locations in metro area."

### D5: Civil Authority Status

Replace `no_central_authority` with `civil_authority_strained` as the Day 1 default:

- **Federal/state officials present** within the transported area (anyone who was physically there at 2:47 PM)
- **NYPD, FDNY, NJ State Police, CT State Police, National Guard units** still operational but overstretched
- **Local governments** (NYC, county, town) still attempting to govern
- **Emergency management** structures activated but insufficient for scale
- **Key tension:** Multiple overlapping jurisdictions (NYC, NJ towns, CT towns, NY State, federal) all claiming authority with no electronic coordination
- **Reality:** Authority holds in cores (Manhattan below 59th, downtown JC, Garden City) but frays at edges. Outer suburban zones are already self-governing by Week 2.

**Tag definitions required (both must be defined in `world_situation.py` `NYC_GEOPOLITICAL_TAGS`):**

```python
"civil_authority_strained": {
    "desc": "Government structures exist across multiple former jurisdictions but are overwhelmed.",
    "effects": [
        "Authority holds in cores, frays at edges",
        "Jurisdictional disputes common",
        "Law enforcement overstretched",
    ],
    "resolves_to": "consolidated_authority",
    "escalates_to": "no_central_authority",
},

"consolidated_authority": {
    "desc": "A unified governance structure has emerged from the competing jurisdictions.",
    "effects": [
        "Law enforcement is coordinated",
        "Faction competition operates within legal frameworks",
    ],
    "resolves_to": None,
    "escalates_to": "civil_authority_strained",
},
```

**Format note:** `effects` must be a list of strings to match the existing tag format in `NYC_GEOPOLITICAL_TAGS`. Both `civil_authority_strained` and `consolidated_authority` must be added. The existing `no_central_authority` tag is retained as-is (it becomes the escalation target).

### D6: Casualty Model

**Transit Day (Day 1):** ~5% immediate casualties (~725K)
- Subway deaths (trains stopped, no power, trapped underground — ~200K affected, ~20K fatal)
- Highway/bridge casualties (vehicles at speed, structural stress)
- Building collapses (structural stress from dimensional transit)
- Hospital patients on life support, mid-surgery, ventilators
- Panic-related deaths (stampedes, falls, heart attacks)

**Week 1:** Additional ~3% (~435K)
- Trapped subway passengers die of dehydration/exposure
- Insulin-dependent diabetics, dialysis patients, critical medication shortages
- Building fires (gas lines rupture, no fire service coverage everywhere)
- Early creature incursions at the perimeter edges (Long Island eastern tip, northern Westchester)

**Month 1 Total:** ~15% cumulative casualties (~2.2M)
- Starvation begins (supply chains severed, no refrigeration, 14.5M people have ~3 days of food in homes)
- Water treatment plants offline (gravity-fed systems work longest; Long Island wells still function)
- Untreated medical emergencies accumulate
- Creature attacks escalate at all edges
- Violence/looting casualties (especially in lawless outer zones)

**Month 1 Survivors:** ~12.3M of 14.5M (~85% survival rate)

---

## PR-A: Lore & World Situation

**Surfaces:** Phase 1 lore references, Phase 3 world-building tables, State data
**Note on Phase 3 surface:** Task A6 modifies `world_situation.py` (a Phase 3 world-building table). This is acknowledged in the surface label. No Phase 3 skill file, CLAUDE.md, or phase-manifest changes are required in this PR — the table modification is self-contained and covered by existing Phase 3 CLAUDE.md domain references.

### Task Breakdown

- [ ] A1. Rewrite `runtime/phases/1-context-loading/lore/core/setting.md` — population 8.4M→14.5M, metro area scope, DESIGNATION update, immediate consequences for expanded geography, jurisdictional chaos section, casualty timeline
- [ ] A2. Rewrite `runtime/phases/1-context-loading/lore/core/geography.md` — regional status table (12 regions), metro internal geography, zone system with expanded perimeter, distance table from metro edges (not Manhattan center), Vaelithar cardinal direction adjustments
- [ ] A3. Update `runtime/phases/1-context-loading/lore/locations.md` — add NJ, LI, Westchester, CT, Rockland named locations (~20 new locations)
- [ ] A4. Update `runtime/phases/1-context-loading/lore/factions-nyc/major.md` — expand Provisional Authority, Sentinels, Exchange, Remnant scope to metro area; add strength increases; add "Regional Equivalents" note; update file header to note metro scope
- [ ] A5. Update `runtime/phases/1-context-loading/lore/factions-nyc/neighborhood.md` — add NJ factions (3), LI factions (3), Westchester/CT factions (4), inter-regional dynamics section
- [ ] A6. Update `runtime/phases/3-resolution/skills/world-building/tables/world_situation.py`:
  - Add `civil_authority_strained` tag definition to `NYC_GEOPOLITICAL_TAGS` (list format for `effects` — see D5)
  - Add `consolidated_authority` tag definition to `NYC_GEOPOLITICAL_TAGS` (list format for `effects` — see D5)
  - Keep `no_central_authority` unchanged
  - Update `generate_initial_world_situation()` to use `civil_authority_strained` instead of `no_central_authority` as Day 1 default
  - Expand `NYC_NEIGHBORHOODS` list from 26 to ~40 (add NJ, LI, Westchester, CT, Rockland neighborhoods)
  - Ensure `generate_initial_world_situation()` assigns initial tags to ALL neighborhoods including new ones
  - Add `civil_authority_strained` to `get_encounter_modifiers()`: `combat -10, social +20, environmental 0, clear +5`
  - Add `consolidated_authority` to `get_encounter_modifiers()`: `combat -15, social +25, environmental 0, clear +10`
  - Update file module docstring header to note "Metro Area" scope (not NYC-only)
- [ ] A7. Update `runtime/state.json`:
  - `world_situation.nyc_wide.geopolitical`: replace `no_central_authority` with `civil_authority_strained`
  - `chronicle[0]`: update population reference 8.4M→14.5M, reference "greater New York metropolitan area"
  - `world_pulse.news`: update to reference broader transported area
  - Verify all other population/geography references consistent
- [ ] A8. Update `runtime/phases/1-context-loading/index.md` — change `locations.md` description from "Named locations in NYC" to "Named locations in metro area"
- [ ] A9. Run validation: `python runtime/scripts/validate_state.py runtime/state.json`
- [ ] A10. Run docs structure check: `python runtime/scripts/validate_docs_structure.py`
- [ ] A11. Run tests: `python runtime/tests/run_all_tests.py 1`

### PR-A Integration Touchpoints (§2)

| Touchpoint | Action |
|---|---|
| 1. Skill file | No skill changes in this PR (lore-only) |
| 2. Phase index.md | Update Phase 1 index.md locations.md description (A8) |
| 3. Phase CLAUDE.md | No changes needed (lore file count unchanged at 14; Phase 3 CLAUDE.md world-building domain entry doesn't enumerate table files) |
| 4. Phase-manifest.md | No changes needed (lore glob `factions-nyc/*` still valid; no new lore directories) |
| 5. Hook enforcement | No hook changes |
| 6. Script registry | No new CLI commands |
| 7. Tests | Run existing validators (A9, A10, A11) |

---

## PR-B: Character Creation & Awakening

**Surfaces:** Phase references (mechanics), Phase skills
**Depends on:** PR-A (for consistent population/geography references in creation docs)

### Task Breakdown

- [ ] B1. Rewrite `runtime/phases/1-context-loading/references/creation.md`:
  - Replace Step 2 (narrative Awakening) with "System Status Screen" flow
  - Add status screen ASCII templates for archetype, aspect, and form selection
  - Replace Step 5 (flat base-10) with System-assessed array rules (steps 5a-5e)
  - Add 3 worked examples showing array assignment + bonuses
  - Update "Character Display Format" to show base array values
  - Update Marcus Chen example to use new array system
  - Keep Steps 1 (Background), 3 (Class grid), 4 (Form pool), 6 (Equipment) largely unchanged
- [ ] B2. Rewrite `runtime/phases/1-context-loading/references/awakening.md`:
  - Remove Phase 2 "first crisis" combat-as-unawakened protocol entirely
  - Remove pre-awakening combat rules section
  - Retain System display template structure (INITIALIZING → ASSESSMENT → COMPLETE) with updated status-screen content
  - Add explicit redirect: "For the full choice flow, see creation.md §Status Screen"
  - Retain class grid reference (shared canonical source)
  - Update archetype/aspect selection sections: remove "GM presents 3 choices based on behavior" and replace with "player selects from full list of 8"
- [ ] B3. Update `runtime/phases/1-context-loading/references/aspects-archetypes.md`:
  - Add "Status Screen Summary" section at top with 1-2 line descriptions per archetype (exact strings for System screen)
  - Add "Status Screen Summary" section for each aspect (exact strings for System screen)
- [ ] B4. Update `runtime/phases/1-context-loading/skills/new-game-setup.md`:
  - Add Step 1.5: "Present Status Screen" between session-zero and character creation
  - Document exact sequence: Transit narrative → status screen → archetype pick → aspect pick → class reveal → form pool → form pick
  - Add note: "The `new-game` CLI command (implemented in PR-C) will replace steps 1-7 with a single invocation. Until PR-C ships, use the manual 3-step sequence below as the active working path."
  - Keep existing 3-step sequence (session-zero → character → game-start) as the current operational path
  - Add "Manual Alternative guidance" section: use the 3-step sequence when independent seeds for world vs. character generation are needed, or for debugging/recovery scenarios; `new-game` is preferred for standard campaign starts once available
  - Update output format section to include status screen display
- [ ] B5. Update `runtime/phases/1-context-loading/references/aspects-archetypes.md` (powers-overview verification) — verify aspect/archetype descriptions in `powers-overview.md` consistent with status screen text; no mechanical changes

### PR-B Integration Touchpoints (§2)

| Touchpoint | Action |
|---|---|
| 1. Skill file | Update new-game-setup.md (B4) |
| 2. Phase index.md | Update Phase 1 index.md: change `new-game-setup.md` description from "Session zero: generate world, character, initial state" to "New campaign initialization: status screen, character creation, world generation" |
| 3. Phase CLAUDE.md | Update Phase 1 CLAUDE.md Skills routing table: update `new-game-setup` trigger from "Session zero / new campaign" to "New campaign initialization (status screen model) / new campaign" |
| 4. Phase-manifest.md | Verify `awakening` description in Phase 1 references still accurate after rewrite. If scope has changed materially, update the manifest entry description. |
| 5. Hook enforcement | No hook changes |
| 6. Script registry | No new CLI commands in this PR (new-game CLI exists only after PR-C) |
| 7. Tests | Manual review of creation.md, awakening.md, new-game-setup.md flows for consistency; run `python runtime/scripts/validate_docs_structure.py` |

---

## PR-C: CLI Implementation

**Surfaces:** Phase scripts, Phase manifest
**Depends on:** PR-A (for consistent world_situation tags), PR-B (for consistent creation flow documentation)

### CLI Changes Required

#### C1: Modified Command — `character`

**Files:** `runtime/scripts/emergence_cli.py`, `runtime/phases/3-resolution/skills/core/scripts/character.py`

**Changes to character.py:**
1. Add `STANDARD_ARRAY = [12, 11, 11, 10, 10, 9, 9, 8]` constant
2. Add `assign_standard_array(stat_order: list[str]) -> dict` function:
   - Takes a list of 8 stat names ordered from highest to lowest priority
   - Zips with STANDARD_ARRAY
   - Returns base stats dict (before bonuses)
   - Validates that exactly 8 unique valid stat names are provided
3. Update test block (`if __name__ == "__main__"`) to demonstrate array assignment for 3 builds

**Changes to emergence_cli.py `cmd_character`:**
1. Add optional `--stat-order` argument (comma-separated stat names, highest to lowest)
2. If provided → parse and call `assign_standard_array()` for base
3. If omitted → fall back to flat base-10 (backward compatibility)
4. Output includes diagnostic `base_array` and `bonuses_applied` to stderr; `attributes` (final values only) in the stdout JSON

#### C2: New Command — `new-game`

**File:** `runtime/scripts/emergence_cli.py`

Add `cmd_new_game(args)` function and `new-game` subparser per D3 design. Internal flow:
1. Set RNG seed
2. Call `generate_session_zero_factions()` → world state
3. Assign standard array to stats per `--stat-order` → base stats
4. Apply aspect, archetype, and background bonuses → final stats
5. Calculate derived stats → full character block
6. Call `generate_scene()` → opening scene
7. Assemble complete state.json structure (persisted fields only)
8. Output JSON

Register in dispatch table: `"new-game": cmd_new_game`

#### C3: Region/Terrain Expansion

**Files:** `runtime/scripts/emergence_cli.py`, `runtime/phases/3-resolution/skills/exploration/scripts/scene.py`

**Note on terrain types vs. region choices:** The current `scene.py` defines 6 terrain types: `urban, forest, plains, ruins, mountain, swamp`. The CLI `--region` argument maps to these terrain types. This PR adds `suburban` and `industrial` as new **terrain types** in both places.

**Note on `crystal` and `shadow`:** The cli-reference.md §CLI Argument Reference currently lists `crystal` and `shadow` as valid `--region` values, but these are not terrain types in `scene.py` — they appear in zone lore only. Task C6 (cli-reference.md update) must remove `crystal` and `shadow` from the Regions argument list, replacing with the accurate set of valid terrain types (`forest, plains, mountain, swamp, ruins, urban, suburban, industrial`). This fixes a pre-existing discrepancy.

**Changes to scene.py:**
1. Add terrain definitions for `suburban` and `industrial`:
   - `suburban`: movement normal, cover moderate, encounter: social/environmental weighted
   - `industrial`: movement normal, cover abundant, encounter: creature/scavenging weighted
2. Add encounter tables for `suburban` (lower creature density, higher social) and `industrial` (moderate creature density, scavenging opportunities)
3. Add creature entries for suburban/industrial settings

**Changes to emergence_cli.py:**
1. Add `suburban` and `industrial` to `--region` choices in `scene`, `creature`, `creatures`, `game-start` subparsers
2. Verify that `generate_scene()` handles the new terrain types

### Task Breakdown

- [ ] C1. Update `character.py` — add STANDARD_ARRAY, `assign_standard_array()`, update test block
- [ ] C2. Update `emergence_cli.py` — modify `character` command with `--stat-order`
- [ ] C3. Update `emergence_cli.py` — add `new-game` command (subparser, cmd_new_game, dispatch table)
- [ ] C4. Update `scene.py` — add `suburban` and `industrial` terrain definitions and encounter tables
- [ ] C5. Update `emergence_cli.py` — add `suburban` and `industrial` to region choices across subparsers
- [ ] C6. Update `runtime/phases/2-action-interpretation/references/cli-reference.md`:
  - Add `new-game` command docs in World & Session section
  - Update `character` with `--stat-order`
  - Update Regions argument list: replace `crystal, shadow` (lore-only, not valid terrain types) with the accurate list `forest, plains, mountain, swamp, ruins, urban, suburban, industrial`
- [ ] C7. Update `runtime/scripts/CLAUDE.md` — add `new-game` to the CLI commands table in the script registry
- [ ] C8. Update `runtime/phases/phase-manifest.md`:
  - Phase 1 `cli_commands`: change from "(none — this phase reads state and lore files)" to "new-game (campaign initialization wrapper — invokes new-game-setup skill)"
  - Phase 3 exploration domain: note `suburban` and `industrial` terrain types added to scene.py
  - **Do not** add `new-game` to Phase 3 core domain — it belongs under Phase 1 as a campaign initialization command, not as a Phase 3 mechanical resolution tool
- [ ] C9. Update `runtime/phases/1-context-loading/skills/new-game-setup.md`:
  - Promote `new-game` CLI to primary invocation (replaces the 3-step manual sequence)
  - Move the 3-step sequence (session-zero → character → game-start) to "Manual Alternative" section
  - Retain Manual Alternative guidance from PR-B: use when independent seeds needed, or for debugging/recovery
- [ ] C10. Run character.py tests: `python runtime/phases/3-resolution/skills/core/scripts/character.py`
- [ ] C11. Verify character CLI: `python runtime/scripts/emergence_cli.py character --aspect ore --archetype guardian --level 1 --stat-order "fortitude,might,presence,willpower,agility,precision,intellect,wisdom"`
- [ ] C12. Verify new-game CLI: `python runtime/scripts/emergence_cli.py new-game --aspect gale --archetype skirmisher --background-type criminal --background-primary agility --background-secondary precision --stat-order "agility,precision,fortitude,might,willpower,intellect,wisdom,presence" --seed 42`
- [ ] C13. Run state validation: `python runtime/scripts/validate_state.py runtime/state.json`
- [ ] C14. Run full test suite: `python runtime/tests/run_all_tests.py 1`
- [ ] C15. Run docs structure check: `python runtime/scripts/validate_docs_structure.py`
- [ ] C16. Run canonical references check: `python runtime/scripts/validate_canonical_references.py`
- [ ] C17. Add test cases to `runtime/tests/` for:
  - Standard array assignment (various stat orders)
  - `new-game` command end-to-end (seed-deterministic output)
  - `civil_authority_strained` encounter modifiers
  - `suburban` and `industrial` terrain handling

### PR-C Integration Touchpoints (§2)

| Touchpoint | Action |
|---|---|
| 1. Skill file | Update new-game-setup.md (C9) — promotes `new-game` to primary invocation |
| 2. Phase index.md | No changes needed (Phase 1 index.md description updated in PR-B) |
| 3. Phase CLAUDE.md | No changes needed (Phase 1 CLAUDE.md Skills table updated in PR-B; no further changes for CLI implementation) |
| 4. Phase-manifest.md | Update Phase 1 cli_commands: add `new-game` (C8); Phase 3 exploration: note suburban/industrial terrain types (C8) |
| 5. Hook enforcement | No hook changes |
| 6. Script registry | Update scripts/CLAUDE.md with `new-game` (C7) |
| 7. Tests | New test cases (C17), run existing suite (C10, C13, C14, C15, C16) |

---

## Validation (All PRs Complete)

1. `python runtime/scripts/validate_state.py runtime/state.json` — State schema passes
2. `python runtime/phases/3-resolution/skills/core/scripts/character.py` — Character system test passes (including array builds)
3. `python runtime/tests/run_all_tests.py 1` — Full test suite passes
4. `python runtime/scripts/validate_docs_structure.py` — Docs structure passes
5. `python runtime/scripts/validate_canonical_references.py` — Canonical reference paths valid
6. `python runtime/scripts/emergence_cli.py new-game --aspect ore --archetype guardian --background-type physical --background-primary fortitude --background-secondary might --stat-order "fortitude,might,presence,willpower,agility,precision,intellect,wisdom" --seed 1` — Complete flow runs, outputs valid JSON
7. `python runtime/scripts/emergence_cli.py character --aspect gale --archetype skirmisher --level 1 --stat-order "agility,precision,fortitude,might,willpower,intellect,wisdom,presence"` — Array assignment works
8. Manual review: creation.md status screen flow is clear and complete
9. Manual review: awakening.md no longer contradicts creation.md; redirects to it
10. Manual review: all population references consistent (~14.5M transported, ~12.3M month-1 survivors)
11. Manual review: geography.md includes all transported areas with accurate populations
12. Manual review: `civil_authority_strained` appears in world_situation.py `NYC_GEOPOLITICAL_TAGS` and state.json
13. Manual review: `consolidated_authority` defined in world_situation.py with encounter modifiers; both tags use list format for `effects` field
14. Manual review: `no_central_authority` removed from initial state (state.json `nyc_wide.geopolitical` and `generate_initial_world_situation()` output) — definition **retained** in `NYC_GEOPOLITICAL_TAGS` as valid escalation target
15. Manual review: cli-reference.md Regions argument list updated to `forest, plains, mountain, swamp, ruins, urban, suburban, industrial` (crystal/shadow removed)
16. Manual review: CLI reference doc updated with new-game command
17. Manual review: phase-manifest.md Phase 1 cli_commands includes `new-game`; Phase 3 exploration notes suburban/industrial terrain
18. Manual review: scripts/CLAUDE.md, Phase 1 index.md, Phase 1 CLAUDE.md all updated
19. Manual review: new neighborhoods in world_situation.py all receive initial tags from `generate_initial_world_situation()`
20. Manual review: `new-game-setup.md` has `new-game` as primary invocation with Manual Alternative section and usage guidance

---

## Risks and Mitigations

- **Risk:** Geographic expansion creates lore contradictions with Vaelithar geography (distances, cardinal directions) — **Mitigation:** Distances in geography.md are rewritten as "from nearest metro edge" not "from city center"; Korveth Plateau size is proportional to continent scale; ~60mi footprint is still small relative to continental geography
- **Risk:** Stat stacking creates extreme values (FOR 18 for Ore × Guardian with physical background) — **Mitigation:** Intentional — specialists should be strong in their niche. The tradeoff is dump stats at 8-9. Combat balance already accounts for varied stat ranges via the 2d6+mod PbtA system
- **Risk:** `new-game` command is complex; bugs in assembly — **Mitigation:** Build from existing working pieces (session-zero, character, game-start); test with multiple seeds; output is JSON so easy to validate; add dedicated test cases (C17)
- **Risk:** Population increase from 8.4M to 14.5M invalidates faction balance — **Mitigation:** Factions are generated dynamically by CLI; the lore files provide flavor, not hard mechanical constraints; existing Manhattan factions remain as-is; new regional factions added to lore
- **Risk:** `civil_authority_strained` and `consolidated_authority` tags not handled by encounter modifiers — **Mitigation:** Both are explicitly added to `get_encounter_modifiers()` in `world_situation.py` (not scene.py — the function lives in world_situation.py); without them, encounters default to base weights (safe fallback)
- **Risk:** Tag `effects` field format inconsistency — **Mitigation:** D5 tag definitions explicitly use list-of-strings format to match existing `NYC_GEOPOLITICAL_TAGS` entries; implementer must not use a plain string. Verified by manual review (exit criterion #13)
- **Risk:** Backward compatibility — old `character` command without `--stat-order` — **Mitigation:** Flat base-10 remains the default when `--stat-order` is omitted
- **Risk:** `awakening.md` rewrite leaves orphaned references elsewhere in runtime — **Mitigation:** Explicit touchpoint audit in PR-B; phase-manifest.md updated; file is rewritten (not deleted) so all path references remain valid
- **Risk:** New neighborhoods in `world_situation.py` get no initial tags — **Mitigation:** PR-A task A6 explicitly requires `generate_initial_world_situation()` to assign tags to all neighborhoods including new ones; verified by state validation (A9)
- **Risk:** Scope creep from 3 PRs being interdependent — **Mitigation:** PR-A is self-contained (lore + data); PR-B is self-contained (docs + flow, does not promote non-existent CLI); PR-C depends on both but they must land first. Each PR has its own validation checks.
- **Risk:** `game-start` and `new-game` overlap causes confusion about which to use — **Mitigation:** D3 explicitly states `game-start` is retained for ongoing scene generation; `new-game` is Day 1 initialization only. `new-game-setup.md` Manual Alternative section (PR-B/C) documents the distinction. Script registry entry for `new-game` notes this scope.
- **Risk:** `crystal` and `shadow` listed as region types in cli-reference.md but absent from scene.py — **Mitigation:** C6 explicitly removes `crystal` and `shadow` from the Regions argument list in cli-reference.md, replacing with the accurate terrain type set. Verified by exit criterion #15.
- **Risk:** PR-B ships before PR-C; runtime Claude attempts to use `new-game` CLI that does not yet exist — **Mitigation:** B4 explicitly retains the 3-step manual sequence as the active working path and notes `new-game` as "forthcoming (PR-C)." The CLI is not promoted to primary invocation until C9.

---

## Exit Criteria

1. A player starting a new campaign sees the System status screen with archetype/aspect/form choices (documented in creation.md)
2. `awakening.md` aligns with the status screen model (no contradictory first-combat-then-choose flow)
3. The System assesses baseline attributes via standard array `[8,9,9,10,10,11,11,12]` (stored as `[12,11,11,10,10,9,9,8]` in code, assigned highest-to-lowest by `--stat-order`), GM assigns to stats based on character description, then aspect/archetype/background bonuses layer on top
4. `new-game` CLI command produces a complete, valid initial state.json in one invocation
5. The transported area covers Manhattan, Brooklyn, Queens, Bronx, Staten Island, Hoboken/NJ, Long Island, Westchester, southern CT, Rockland
6. Civil authorities are present but strained (`civil_authority_strained`) in state.json and world_situation.py
7. `consolidated_authority` is defined as the resolution target for `civil_authority_strained`
8. Population figures are consistent (~14.5M) across all documents
9. Casualty model documented: ~15% in first month, ~85% survive
10. State validates, character script tests pass, full test suite passes, `new-game` CLI runs end-to-end
11. CLI reference doc updated with all changes; `crystal`/`shadow` removed from Regions argument list
12. All 7 integration touchpoints addressed per PR (phase-manifest, script registry, phase index.md, phase CLAUDE.md verified)
13. New tag definitions (`civil_authority_strained`, `consolidated_authority`) use list format for `effects` field, consistent with existing `NYC_GEOPOLITICAL_TAGS` entries
14. `no_central_authority` removed from initial state (state.json + `generate_initial_world_situation()`) — definition retained in `NYC_GEOPOLITICAL_TAGS` as valid escalation target
15. New neighborhoods receive initial tags from `generate_initial_world_situation()`
16. `base_array`/`bonuses_applied` are transient CLI output only — not persisted in state.json
17. `new-game-setup.md` has `new-game` as primary invocation (post PR-C) with Manual Alternative section documenting when to use the 3-step sequence instead
