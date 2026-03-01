# EMERGENCE: THE EXILE — Changelog

## v4.5.10 (2026-02-08) — Layer 2 Resource Economy & Equipment Rebalance

### Problem Addressed
Layer 2 audit found 4 systemic issues: Mana pool 39% larger than Stamina (casters never depleted across 3-fight day); armor T4/T5 gave exponential +2/tier bonus creating unhittable tanks; survival economy rules existed in reference docs but had no mechanical backing in conditions.py; composure was inert for non-Speaker builds with only 4 damage sources.

### Mana Rebalancing
- **Formula:** `10 + (INT×2) + (WIL×2) + Lv` → `10 + (INT×2) + WIL + Lv` (WIL from ×2 to ×1)
- **Short rest recovery:** 50% → 33% (Stamina stays at 50%)
- **Impact:** L5 caster mana 79→65 (-18%). 3-fight budget: 59% remaining → 17% remaining
- **Design intent:** Casters must now manage mana across encounters; conserve T1 to sustain, or burn T2/T3 and risk depletion

### Armor Tier Flattening
- **Tier bonus progression:** T4 +4→+3, T5 +6→+4 (linear +1/tier across all tiers)
- **New armor totals:** Heavy T4=+9 (was +10), T5=+10 (was +12)
- **Impact:** Reduces extreme DEF ceiling by 1-2 points at T4/T5; T1-T3 unchanged

### Shield Tier System (new)
- Shields now scale with tiers (previously flat +1/+2)
- Light Shield: T1=+1, T2=+1, T3=+2, T4=+2, T5=+3
- Heavy Shield: T1=+2, T2=+2, T3=+3, T4=+3, T5=+4
- Shield tier bonus increases at half the rate of armor (+1 per 2 tiers) since shields stack with armor

### Survival Conditions
- **Starving:** -1 all rolls/day without food (cumulative, max -4); no long rest HP recovery; death at 7 days
- **Dehydrated:** -2 all rolls/day without water (cumulative, max -6); halved short rest recovery; death save at day 4
- **Fatigued:** -1 all rolls, -2m movement, cannot benefit from short rest; removed by long rest with food + shelter
- **Rest gating:** Long rest requires food + shelter (without food: HP recovers to 50% only). Short rest requires water (without: recovery halved)

### Composure Pressure Sources (6 new)
- **Ally drops to 0 HP:** 3 composure damage (WIL DC 9 negates)
- **Ally dies:** 5 composure damage (no save)
- **Outnumbered 2:1+:** 1/round (WIL DC 7 negates, per round)
- **Combat exceeds 6 rounds:** 2/round after round 6 (no save)
- **Horrific scene:** 3-5 composure damage (WIL DC 11 for half)
- **Failed death save:** 2 to all witnesses (WIL DC 9 negates)
- **Impact:** Non-Speaker L5 reaches Shaken after 2 tough fights; Speakers remain resilient due to higher pool

### Updated Tests
- **`tests/balance_test_a4.py`** — rewritten with actual technique cost averages (T1 stam=2.14, T1 mana=2.22) and 3-fight simulation with short rest recovery
- **`tests/balance_test_resources.py`** (new) — 24 assertions: mana formula validation, stamina formula unchanged, pool parity check, survival conditions exist, composure triggers exist, composure budget, 3-fight depletion simulation
- **Result:** 23/24 existing suites pass (B3 pre-existing); 24/24 new resource tests pass; 6/6 A4 pass

### Updated Reference Docs
- `references/math-assumptions.md` — armor tiers, shield tiers, mana formula, technique costs, composure sources
- `references/core-balance-templates.md` — mana formula in NPC template
- `references/conditions.md` — rest recovery rates, rest gating, survival conditions, composure damage table
- `references/equipment.md` — armor tier table, shield tier table
- `references/scarcity.md` — cross-references to conditions.py
- `references/hard-rules.md` — composure drain sources expanded

---

## v4.5.9 (2026-02-08) — Combat Balance Retuning

### Problem Addressed
Layer 1 audit found 4 structural balance issues: Aggressive stance dominated at ~2.87× Balanced DPR; enemy ATK (`Lv+2`) outpaced PC DEF by L15; PC ATK vs enemy DEF collapsed without talent stacking; no codified math assumptions for equipment/techniques/skills.

### Stance Rebalancing
- **Aggressive:** AP 4→3, ATK +2→+1, RP 1→0 (ratio now 1.2-1.6× Balanced, was 2.87×)
- **Focused:** DMG +0→+4, advantage on attacks (ratio now 1.0-1.4× Balanced)
- **Mobile:** DEF +0→+1 (kiting survivability; DPR unchanged at ≈1.0×)
- **Balanced/Defensive:** unchanged (Defensive DPR 0.38× offset by 53% damage reduction)

### Enemy Formula Rebalancing
- **ATK formula:** `level + 2` → `3 + (level * 2) // 5` (+0.4/level instead of +1/level)
  - L1=+3, L5=+5, L10=+7, L15=+9, L20=+11
  - Enemy hit rate vs average PC: stable ~42% from L1-L15
- **DEF formula:** `10 + (level // 2)` → `10 + (level * 2) // 5` (+0.4/level instead of +0.5/level)
  - L1=10, L5=12, L10=14, L15=16, L20=18
  - Raw PC hit rate: stable ~58% from L5-L20

### Equipment ATK Bonus (new)
- Weapon tiers now grant ATK bonuses: T1=+0, T2=+1, T3=+2, T4=+3, T5=+4
- Replaces level-based attack bonus — better weapons are more precise
- PC total ATK = attribute modifier + weapon tier ATK + Weapon Focus tree

### New Files
- **`references/math-assumptions.md`** — authoritative balance reference covering resolution math, PC ATK/DEF progression, enemy formulas, hit rate matrices, stance DPR budgets, equipment/technique/talent/skill assumptions
- **`tests/balance_playtest.py`** — 42 assertions across 9 test categories: stance DPR ratios, DPR stability across levels, hit rate spot checks, equipment scaling, focused vs raw build gap, threat tier progression, group encounter scaling, enemy formula verification, defensive survival validation

### Updated Files
- `scripts/combat.py` — STANCES dict
- `scripts/creature.py` — ATK and DEF formulas
- `references/equipment.md` — weapon tier ATK Mod column and examples
- `references/combat.md` — stance table with RP column
- `references/enemies.md` — formulas, scaling table, 4 sample stat blocks
- `references/core-balance-templates.md` — enemy stat baseline, NPC sample
- `tests/unified_entity_test.py` — version bump to v4.5.9
- `tests/death_rate_test_d3.py` — thresholds updated for flattened enemy ATK
- `tests/stress_test_munchkin.py` — reads aggressive ATK from STANCES dict
- `tests/run_all_tests.py` — added balance_playtest to test runner

### Test Results
- **24/24 test suites pass** (230s total)
- Balance playtest: 42/42 assertions pass
- Unified entity test: 146/146 assertions pass

---

## v4.5.8 (2026-02-08) — Unified Entity & Combat System

### Problem Addressed
PCs, Awakened NPCs, and Creatures used three separate mechanical systems: contradictory stat formulas (NPC HP used `FOR×2+MIG+Lv×5` vs PC's `MIG×2+FOR×2+Lv×3`), incompatible condition vocabularies (conditions.md vs combat.md), prose-based behavior patterns (not machine-readable), and hardcoded NPC abilities disconnected from real forms.

### H1: Unified Condition Vocabulary
- **Created `scripts/conditions.py`** — single source of truth for 29 standardized conditions
  - 13 combat conditions, 5 beneficial, 3 HP states, 5 composure states, 3 additional
  - `validate_ability_conditions()` ensures abilities reference valid conditions
  - `get_hp_state()` / `get_composure_state()` for AI state tracking
- **Rewrote `references/conditions.md`** with authoritative v4.5.8 condition tables
- **Added cross-reference** in `references/combat.md` pointing to conditions.md as authoritative source

### H2: Unified Stat Architecture
- **Fixed NPC stat formulas** — `npc.py` now imports `calculate_derived_stats` from `character.py`
  - HP, Stamina, Mana, Composure, DEF, Initiative, Movement all guaranteed identical to PC formulas
  - NPC HP at high levels decreases (was `Lv×5`, now correct `Lv×3` matching PC scaling)
  - NPC Stamina bug fixed (was using MIG instead of AGI)
  - NPC Composure added (was missing entirely)
- **Fixed creature.py initiative** — removed `random.randint(1,4)` pre-roll that double-dipped with combat.py's 2d6
- **Fixed character.py display strings** — corrected HP/Stamina formula display, added Composure row
- **Fixed reference docs** — combat.md initiative, enemies.md formulas/samples, core-balance-templates.md HP table and NPC template

### H3: Creature Ability Unification
- **Rewrote all 19 creature abilities** in `creature.py` with structured condition-reference format
  - Each ability has `mechanic`, `condition`, `save`, `duration` fields
  - All condition references validated against `STANDARDIZED_CONDITIONS`
  - Imported conditions.py for cross-module validation

### H4: Behavior Tree System
- **Created `scripts/behavior.py`** — machine-readable decision trees replacing prose behavior strings
  - 7 creature templates: mindless (2 rules) through genius (10 rules)
  - 8 NPC templates: one per archetype (striker, guardian, hunter, skirmisher, mender, warden, analyst, speaker)
  - Complexity scales with tier: grunt=2 rules, veteran=3, awakened=5, champion=7, legend=10
  - Priority-ordered rules with condition expressions and target selection
- **Updated creature.py** and **npc.py** to return behavior trees instead of prose strings

### H5: NPC Ability Unification (Witnessed Learning Bridge)
- **Created `scripts/technique_registry.py`** — 46 curated techniques from 21 real forms + 6 simplified abilities
  - Each technique: `{name, form, tier, ap_cost, resource_cost, tag, effect, condition_output, learnable, learn_dc}`
  - `select_npc_techniques(archetype, aspect, tier, level)` assigns form-appropriate abilities
  - Grunt/veteran get simplified abilities (not learnable)
  - Awakened+ get real form techniques (learnable via Witnessed Learning, DC 14 + tier×2)
- **Deleted `SIGNATURE_ABILITIES`** from npc.py — replaced with registry-based selection

### H6: Unified Combat State Schema
- **Added `create_entity_state()` to `scripts/combat.py`** — normalizes PC/NPC/creature into identical 21-key state dict
  - All entity types produce same output keys: `entity_type, name, level, hp, stamina, mana, composure, physical_def, mental_def, attack_mod, damage_mod, weapon_base, armor, initiative_mod, movement, crit_threshold, conditions, behavior, abilities, turn_state, combat_state`
  - `attack_roll()` can operate on any entity type without special-casing

### H7: Integration Testing
- **Created `tests/unified_entity_test.py`** with 146 assertions across 7 test categories:
  - Formula parity (PC ↔ NPC at 5 levels)
  - Condition vocabulary consistency
  - Behavior tree validity (structure + default fallback + tier trimming)
  - Technique registry & selection (tier-appropriate counts)
  - Combat state normalization (21 shared keys across all 3 entity types)
  - Cross-entity combat simulation (PC vs NPC win rate 25-75%)
  - Creature initiative determinism

### System Health After v4.5.8
| Metric | Value | Status |
|--------|-------|--------|
| PC ↔ NPC formula parity | 6/6 stats match at all levels | Fixed (was 3/6) |
| Standardized conditions | 29 | Up from ~18 |
| Creature abilities with structured conditions | 19/19 | Was 0/19 |
| Machine-readable behavior trees | 15 templates | Was 0 (all prose) |
| NPC techniques from real forms | 46 registry + 6 simplified | Was 10 hardcoded |
| Tests passing | 23/23 | Up from 22 |
| Unified entity test assertions | 146/146 | New |

### Files Created
- `scripts/conditions.py` — standardized condition vocabulary
- `scripts/behavior.py` — behavior tree templates
- `scripts/technique_registry.py` — curated technique registry for NPCs
- `tests/unified_entity_test.py` — integration tests

### Files Modified
- `scripts/npc.py` — unified stats + behavior + abilities
- `scripts/creature.py` — initiative fix + ability format + behavior import
- `scripts/character.py` — display string fixes + Composure row
- `scripts/combat.py` — entity state normalization
- `references/conditions.md` — complete rewrite
- `references/combat.md` — initiative fix + condition cross-ref
- `references/enemies.md` — complete rewrite with correct formulas
- `references/core-balance-templates.md` — HP table + NPC template fixes
- `tests/run_all_tests.py` — registered new test

---

## v4.5.7 (2026-02-07) — Awakening Cross-System Integration & Keystone Restrictions

### Problem Addressed
After v4.5.6 connected the talent and form systems via technique tags, tag-aware talents, and combat loop rules, three gaps remained: (1) all 64 awakenings were isolated from the talent/form systems — zero references to technique tags, conditions, or archetype/aspect unique mechanics; (2) 4 of 8 aspect pools (Pyre, Gale, Radiance, Anima) lacked tag-aware talents; (3) restriction/drawback talents sat at ~2.1% vs the 3%+ target, with no PoE2-style binary keystones.

### G1: Awakening Cross-System Clauses (64 modifications)
- **Added L10 cross-system clause to all 64 awakenings** in `classes.md`
  - Each clause references technique tags (Opener, Finisher, Exploit, Setup, Reaction, Sustained), standardized conditions (Burning, Frozen, Prone, etc.), and/or archetype/aspect unique mechanics (Momentum, Threat, Geo-Armor, Shadow Debt, etc.)
  - Two formats handled: explicit L10 bullet (Ore, Radiance, Shroud, Aether) and Scales description (Tide, Pyre, Gale, Anima)
  - All 64 awakenings now bridge the three systems (Talents ↔ Forms ↔ Awakenings)
  - AI-parsability: all clauses are SIMPLE (binary checks, no new counters)

### G2: Tag-Aware Talents for Missing Aspect Pools (4 new talents)
- **EMBER EXPLOITATION** (T2, Pyre): Exploit-tagged techniques vs Burning targets deal +3 fire damage + gain Burning Engine stack
- **STORM REACTION** (T2, Gale): Reaction-tagged techniques generate Storm Charges (max 5); 3+ charges empower next Finisher with +1d6 lightning per charge
- **AURA PROPAGATION** (T2, Radiance): Setup-tagged techniques affect +1 target within Aura radius; Sustained benefits extend to Aura-covered allies
- **FORM FINISHER** (T2, Anima): Finisher-tagged techniques in beast form extend form duration +1 round and recover 2 Stamina; Opener after form switch gains advantage

### G3: Keystone Restriction Talents (6 new talents, General pool)
- **RESOLUTE TECHNIQUE** (T2): Can never critically hit; attacks never critically miss, minimum 50% of max damage, +2 to hit
- **GLASS CANNON** (T2): -30% max HP; +25% damage, Exploit-tagged techniques deal +50% bonus
- **PACIFIST'S OATH** (T3): Can never deal direct damage; doubled healing, doubled buff durations, auto-succeed defensive Reactions, +1 RP
- **TIRELESS SENTINEL** (T2): Can never use Aggressive or Mobile stances; Defensive stance: 3 AP, +6 DEF, +1 RP
- **ELEMENTAL PURITY** (T3): Can only deal damage of one chosen element; +50% element damage, -2 to saves vs your conditions, ignore resistance
- **SPIRIT WALKER** (T3): Can never wear armor heavier than Light; DEF = 8 + WIL + WIS, see invisible/ethereal, Setup techniques reveal hidden enemies

### G4: Updated Counts
- General pool: 119 → 125 talents (+6 keystones)
- Pyre: 20 → 21, Gale: 20 → 21, Radiance: 21 → 22, Anima: 21 → 22
- Total: ~473 → ~483 talents
- Restriction/drawback category: ~2.1% → ~3.5% (target met)

### G5: Test Updates
- Added all 10 new talents to `class_fantasy_audit.py` constants (GENERAL_TALENTS, ASPECT_TALENT_POOLS, MECHANIC_TALENTS)
- All 22 tests pass (161.9s)
- All 64 classes pass fantasy audit (min 6, max 70, avg 32.4 exclusive tropes)

### System Health After v4.5.7
| Metric | Value | Status |
|--------|-------|--------|
| Awakenings with cross-system clauses | 64/64 (100%) | Target met |
| Aspect pools with tag-aware talents | 8/8 (100%) | Target met |
| Restriction/drawback % | ~3.5% | Target met (was 2.1%) |
| Total talents | ~483 | Up from ~473 |
| Tests passing | 22/22 | All pass |
| Classes passing fantasy audit | 64/64 | All pass |

---

## v4.5.6 (2026-02-07) — Cross-System Integration & Combat Loop Refinement

### Problem Addressed
After v4.5.5 added technique tags and cross-form exploit techniques, a holistic audit revealed 7 remaining gaps: technique tags existed in form headers but were not applied inline to individual techniques (380/400 combat and 332/363 magic techniques had no inline tag); the talent system had zero integration with technique tags (0/457 talents referenced any tag); no anti-spam mechanism prevented using the same 1 AP technique 3 times per turn; no mid-combat resource recovery existed beyond basic attacks; 15/20 combat forms had zero battlefield control techniques; and the Frozen and Broken conditions had zero talent support.

### F1: Inline Technique Tag Annotations
- **Applied ~364 inline `*Tag: X*` annotations** across all 37 combat+magic forms
  - Combat forms: 177 tags across 20 forms (Opener, Finisher, Flourish, Setup, Sustained, Reaction, Exploit)
  - Magic forms: 195 tags across 17 forms
- Every technique now has its tag visible in the technique description, not just in form headers
- Players and AI-GM can determine which techniques are Openers/Finishers/etc. from the technique text alone

### F2: Tag-Aware Talents (16 New Talents)
Added 16 talents that bridge the previously-isolated talent and form systems by referencing technique tags:

**General Pool — Tag Mastery Tree (4 talents):**
- OPENING GAMBIT (T1): Opener hit → next attack +2 to hit
- FINISHING BLOW (T2): Finisher hit → recover 3 Stamina/Mana (stacks with base Finisher Recovery)
- FLOURISH MASTERY (T2): Flourish techniques +2 damage, conditions +1 round duration
- SUSTAINED FOCUS (T2): +1 all rolls while maintaining Sustained technique; dropping grants +2 next attack

**Archetype Pool (8 talents, 1 per archetype):**
- MOMENTUM EXPLOIT (Striker T3): Exploit techniques generate 2 Momentum; Finisher at 3+ Momentum deals +Momentum×2
- THREATENING COUNTER (Guardian T3): Reaction techniques generate 2 Threat; Threat-enhanced Setups doubled duration
- PRECISION EXPLOIT (Hunter T3): Exploit at 3+ Exposure stacks → ×2.0 total damage
- EVASION EXPLOIT (Skirmisher T3): Reaction dodge → next Opener gets advantage +3 damage
- TRIAGE EXPLOIT (Mender T3): Exploit healing removes condition → ally transfers condition to next enemy hit
- TERRITORIAL SETUP (Warden T3): Setup techniques create 3m Territory zones, -2 saves within
- ANALYTICAL EXPLOIT (Analyst T3): 2+ rounds observing → Exploit techniques auto-succeed condition checks
- PRONOUNCED SETUP (Speaker T3): Setup conditions spread to 5m during Pronouncement

**Aspect Pool — Condition-Aware Talents (4 talents):**
- SHATTER POINT (Ore T2): Hit Frozen enemy with bludgeoning → +8 damage + Exposed (Tide→Ore chain)
- PERMAFROST (Tide T2): Frozen can't be removed by damage (only fire/action); +3 damage vs Frozen
- MORALE PREDATOR (Shroud T2): Enemy becomes Broken → free Reaction without RP; Frightened Setup deals Composure damage
- CONDITION RESONANCE (Aether T2): Condition on target with existing condition → +1 round; 3rd condition auto-upgrades

**Talent count: 457 → 473 (+16)**

### F3: Combat Loop Rules (3 New Rules)
Added three rules to `combat.md` that create turn-structure incentives, prevent technique spam, and provide mid-combat recovery:

1. **Repetition Penalty:** Using the same technique more than once per turn incurs cumulative -2 penalty to hit per repeat. Basic attacks are exempt. Resets at start of next turn.
2. **Finisher Recovery:** Hitting with a Finisher-tagged technique recovers Stamina or Mana equal to the technique's AP cost (once per turn, must hit).
3. **Second Wind:** Once per combat, 2 AP action: recover 25% max Stamina or Mana (rounded up). Provokes opportunity attacks. Cannot use while Stunned/Restrained/Frozen.

Also added updated AI State Tracking JSON format for v4.5.6 with `techniques_used`, `repetition_penalty`, `finisher_recovered`, and `second_wind_used` fields.

### F4: Battlefield Control Techniques (8 New Techniques)
Added 1 zone/terrain technique to each of 8 combat forms that previously had zero battlefield control:

| Form | New Technique | AP | Effect |
|------|--------------|-----|--------|
| Heavy Blade | SWORD WARD | 2 | Plant blade to create 3m barrier zone (+3m to cross, -2 ATK within), 2 rounds |
| Axe | TIMBER BARRIER | 1 | Chop object to create difficult terrain in 3m (+3m, 1d4 debris damage) |
| Medium Blade | BLADE CURTAIN | 1 | 2m zone: enemies entering provoke free attack, cannot move while active |
| Light Blade | CALTROPS | 1 | 3m radius difficult terrain, 1d4 + AGI save or Slowed |
| Dual Wield | WHIRLING DEFENSE | 1 | 2m danger zone: 1d6 slashing to entrants, +1 DEF |
| Unarmed Strike | PRESSURE WAVE | 2 | 3m radius: AGI save or pushed 2m + prone, dust cloud +1 DEF vs ranged |
| Aggressive Arts | INTIMIDATING PRESENCE ZONE | 1 | 5m aura: WIL save or can't approach, 2 Composure damage/turn |
| Mounted Combat | CAVALRY SCREEN | 1 | 4m trail of difficult terrain behind charge, mergeable with allies |

### Technique Counts

| Category | Before (v4.5.5) | After (v4.5.6) | Change |
|----------|-----------------|----------------|--------|
| Combat techniques | ~434 | ~442 | +8 (battlefield control) |
| Magic techniques | ~370 | ~370 | +0 (tags only) |
| Utility techniques | 338 | 338 | +0 |
| Inline technique tags | ~58 | ~422 | +364 annotations |
| **Grand total** | **~1,142** | **~1,150** | **+8 techniques, +364 tags, +16 talents, +3 rules** |

### Test Results
- All 22 tests pass (46.5s)
- Class Fantasy Audit: ALL 64 classes pass (min=6, max=70, avg=32.4 exclusive tropes)

---

## v4.5.5 (2026-02-07) — Form System Redesign: Cross-Form Synergy & Technique Tags

### Problem Addressed
Forms (57 total: 20 combat, 17 magic, 20 utility) operated in complete isolation — zero techniques referenced conditions from other forms, zero had technique tags constraining turn structure, and 28% of T1 techniques were generic damage bolts interchangeable across forms. Utility forms were uneven: 10 fully written, 7 partial (missing Variant C + T4 passives), 3 stubs (only 4 base techniques, no variants). Compared to 13 reference systems (PF2e, Lancer, DOS2, Tome of Battle, Ars Magica, Spheres of Power, PoE2, WotR, Dragon's Dogma 2, BG3/5e, FFT, Grim Dawn, Morrowind), Emergence lacked action grammar tags, cross-form condition exploitation, and reaction techniques.

### Architecture Model Adopted
**Hybrid Model** combining PF2e Action Grammar (technique tags), DOS2 Condition Exploitation (cross-form bridges), 5e Concentration Slot (sustained techniques), with Emergence's existing variant system enhanced.

### E1: Standardized Conditions & Technique Tags
- **Added 13 Standardized Conditions** to `combat.md` with explicit mechanical effects, durations, and removal methods: Bleeding, Burning, Frozen, Prone, Dazed, Slowed, Frightened, Blinded, Stunned, Restrained, Poisoned, Exposed, Broken
- **Added 7 Technique Tags** to `combat.md`: Opener, Finisher, Flourish, Reaction, Sustained, Setup, Exploit — each constraining WHEN a technique can be used within a turn
- **Added AI State Tracking Format** (JSON) and **Complexity Budget** (max 3-5 conditions/target, max 8 battlefield-wide, max 3 zones, ~15-20 total state objects)
- **Added Condition Output/Input metadata** to all 37 combat+magic form headers

### E2: Cross-Form Exploit Techniques (11 Priority Forms)
Added 1 Exploit technique to each of 11 high-priority forms, creating cross-form condition bridges:

| Form | New Technique | Exploits | Bridge |
|------|--------------|----------|--------|
| Heavy Blade | BURNING CLEAVE | Burning | Fire magic → melee exploitation |
| Heavy Crush | SHATTER | Frozen | Ice magic → crushing exploitation |
| Axe | RENDING EXECUTION | Bleeding | Self-setup exploitation |
| Shield | MAGNETIC REPULSE | Electrified | Lightning → shield exploitation |
| Longbow | SHATTERING SHOT | Frozen/Slowed | Ice/debuff → ranged exploitation |
| Unarmed Strike | PRESSURE POINT EXPLOIT | Any debuff | Universal debuff exploitation |
| Fire | DETONATION | Bleeding | Melee bleed → fire exploitation |
| Water/Ice | STEAM BURST | Burning | Fire → ice counter-exploitation |
| Shadow | NIGHTMARE GRASP | Frightened | Fear → shadow exploitation |
| Earth | BURIAL | Prone | Knockdown → earth exploitation |
| Healing | PURIFYING SURGE | Any condition | Condition → healing efficiency |

### E3: Remaining Exploit + Reaction Techniques (All 37 Forms)
- **Added 14 Exploit techniques to remaining combat forms**: Impaling Thrust, Punishing Riposte, Concussive Follow-Up, Assassin's Mark, Exploit Weakness, Harrying Volley, Pinpoint Bolt, Flash Follow-Up, Savage Onslaught, Submission Hold, Punishing Counter, Terror Strike, Trampling Charge, Environmental Exploitation
- **Added 12 Exploit techniques to remaining magic forms**: Conducted Surge, Dust Devil, Searing Judgment, Kinetic Propulsion, Retributive Ward, Sanguine Puppet, Domination, Accelerated Decay, Spirit Bind, Nature's Vengeance, Phantom Assault, Temporal Anchor
- **Added 2 Reaction techniques to combat forms**: Tremor Response (Heavy Crush), Defensive Spur (Mounted Combat)
- **Added 6 Reaction techniques to magic forms**: Flashpoint (Fire), Static Discharge (Lightning), Emergency Heal (Healing), Force Barrier (Force), Spectral Shield (Spirit), Blink Dodge (Dimensional)
- **Total: 37 Exploit techniques + 8 Reaction techniques across all combat+magic forms**

### E4: Utility Form Completion
- **Completed 7 partial utility forms** (added Variant C + T4 passives):
  - Diplomacy: Variant C — ALLIANCE (coalition-building, diplomatic immunity)
  - Deception: Variant C — CON ARTISTRY (long cons, narrative construction)
  - Performance: Variant C — THEATRICS (dramatic entrances, method acting)
  - Alchemy: Variant C — TRANSMUTATION (material refinement, elemental conversion)
  - Surgery: Variant C — PROSTHETICS (artificial limbs, surgical implants)
  - Crafting: Variant C — TINKERING (mechanisms, clockwork devices)
  - Smithing: Variant C — METALLURGY (alloy analysis, exotic metalwork)
- **Fully built 3 stub utility forms** (4 base techniques → 8+ base + 3 variants):
  - Investigation: DETECTIVE / RESEARCHER / PROFILER variants
  - Knowledge: LOREMASTER / NATURALIST / ARCANIST variants
  - Animal Handling: BEAST TAMER / TRAINER / MOUNTED SPECIALIST variants
- **Utility technique count: 296 → 338 (+42 techniques)**

### E5: T1 Deduplication Pass
Revised 15 most generic T1 techniques to add unique mechanical identities:

**Magic bolts (8 revised):** Each bolt now has a distinct rider effect matching its school identity:
- Flame Bolt: +2 damage vs already-Burning targets (self-form synergy)
- Stone Bolt: Creates difficult terrain on hit (terrain control)
- Shadow Bolt: Dims light around target, granting concealment (stealth setup)
- Blood Bolt: Can pay 4 HP instead of 2 Mana for +2 damage (resource tradeoff)
- Light Bolt: Illuminates target — no cover/concealment/invisibility (anti-stealth)
- Thorn Bolt: Embedded thorn deals 1d4 if target moves (movement punishment)
- Air Blade: +2 damage at different elevations, ignores soft cover (positional)
- Force Bolt: Push 2m OR pull 2m on hit (positioning choice)

**Blood Armor revised:** Starts at +1 DEF, gains +1 per hit taken (max +4), resets if undamaged 1 round (reactive scaling instead of static +2 DEF)

**Combat T1s (6 revised):**
- Snap Shot (Shortbow): +1 hit on repeated shots vs same target (rapid acquisition)
- Running Shot (Shortbow): +2 DEF when moving away from target (kiting bonus)
- Bolt Shot (Crossbow): Reveals target's exact DEF value on first hit (reconnaissance)
- Aimed Bolt (Crossbow): Marks target for +2 hit on next crossbow attack (team setup)
- Aimed Throw (Thrown): Free called shots without penalty (precision targeting)
- Mounted Strike (Mounted): +1 damage per 2m mount moved (charge scaling)

### Cross-Form Condition Flow (v4.5.5 Design Map)
```
SETUP (applies condition)              EXPLOIT (uses condition)
═══════════════════════════════════    ═══════════════════════════
Axe/Light Blade → BLEEDING ──────────→ Fire (Detonation), Blood (Puppet)
Fire/Pyre → BURNING ─────────────────→ Heavy Blade (Burning Cleave), Water/Ice (Steam)
Water/Ice → FROZEN ──────────────────→ Heavy Crush (Shatter), Force (Propulsion)
Heavy Crush/Earth → PRONE ───────────→ Earth (Burial), Longbow (Shattering Shot)
Mind/Heavy Crush → DAZED ───────────→ Mind (Domination), Medium Crush (Concussive)
Water/Polearm → SLOWED ─────────────→ Finesse Blade (Exploit), Dimensional (Anchor)
Shadow/Intimidation → FRIGHTENED ───→ Shadow (Nightmare), Death (Decay), Spirit (Bind)
Light/Thrown → BLINDED ──────────────→ Illusion (Phantom), Light Blade (Assassin's Mark)
Grappling/Earth → RESTRAINED ───────→ Crossbow (Pinpoint Bolt), Beast/Nature (Vengeance)
Alchemy/Beast/Nature → POISONED ────→ Death (Accelerated Decay), Unarmed (Pressure Point)
```

### Technique Counts

| Category | Before (v4.5.4) | After (v4.5.5) | Change |
|----------|-----------------|----------------|--------|
| Combat techniques | ~400 | ~434 | +34 (20 Exploit + 2 Reaction + 12 tagged) |
| Magic techniques | ~340 | ~370 | +30 (17 Exploit + 6 Reaction + 7 tagged) |
| Utility techniques | 296 | 338 | +42 (7 Variant C + 3 full forms) |
| **Grand total** | **~1,036** | **~1,142** | **+106 techniques** |

### Test Results
- All 22 tests pass (47.9s)
- Class Fantasy Audit: ALL 64 classes pass (min=6, max=70, avg=32.4 exclusive tropes)

---

## v4.5.4 (2026-02-07) — Talent System Redesign: Mechanical Depth Overhaul

### Problem Addressed
404 talents felt samey — 25% were pure numeric modifiers, only 1% had resource tradeoffs, 2% had interaction effects, 0.5% had restrictions/drawbacks. Almost every chain was linear (T1=+small → T4=+huge + once/rest). Compared to 10 reference systems (PF2e, Lancer, BitD, ICON, Fabula Ultima, PoE2, Grim Dawn, Deadfire, DOS2, WotR), Emergence was severely underweight in Mode Switches, Resource Tradeoffs, Interaction Effects, and Restrictions.

### Phase A: General Pool Rework (100 → 115 talents)
- **Branched 4 survivability chains at T2**: Each chain now offers a numeric path (T2a) and a mechanical path (T2b)
  - TOUGH → TOUGHER (HP) | REACTIVE FORTITUDE (damage-triggered counter)
  - QUICK → LIGHTNING REFLEXES (speed) | FLASH COUNTER (miss-triggered free attack)
  - RESILIENT → IRON WILL (saves) | DEFIANT RESOLVE (Resolve counter system)
  - THICK SKIN → ARMOR SKIN (DR) | ABLATIVE SHELL (temporary combat armor pool)
- **Branched weapon chain**: WEAPON FOCUS → WEAPON SPECIALIZATION (numeric) | ADAPTIVE WEAPON (miss-recovery + stance switching)
- **Branched critical chain**: CRITICAL FOCUS → IMPROVED CRITICAL (crit range) | TACTICAL CRITICAL (crits as tactical tools: prone/disarm/blind/push)
- **Added 7 Combat Innovation talents**: SETUP STRIKE (create/exploit combo), EXPLOIT OPENING (party synergy), ADRENALINE RUSH (AP burst + debt), OVERCOMMIT (resource tradeoff), COUNTER-MOMENTUM (parry→damage chain), BLOODPRICE FURY (HP as offense), DEATH'S DOOR DEFIANCE (restriction/mode switch at 25% HP)

### Phase B: Archetype Unique Mechanics (8 × 2 = 16 new talents)
Each archetype now has a **unique mechanical verb** that no other archetype uses:

| Archetype | Unique Mechanic | New Talents |
|-----------|----------------|-------------|
| Striker | **Momentum Stacking** (kills/crits build counter, max 5) | Momentum Surge, Cascading Violence |
| Guardian | **Threat** (generate from tanking, spend for powerful effects) | Threat Conversion, Gravitational Presence |
| Hunter | **Vulnerability Tracking** (hits build Exposure, unlock Perfect Shot/Lethal Knowledge) | Perfect Shot, Lethal Knowledge |
| Skirmisher | **Evasion Tokens** (dodges generate tokens for guaranteed hits/stealth) | Evasion Strike, Phantom Dance |
| Mender | **Triage Priority** (healing below 50% grants Life Debt — next hit heals instead) | Debt Collector, Chain of Life |
| Warden | **Territory** (persistent zones with stacking penalties) | Territorial Fortification, Killing Ground |
| Analyst | **Tactical Clock** (observation advances clock for coordinated strikes) | Coordinated Strike, Grand Strategy |
| Speaker | **Pronouncement** (declare battlefield-wide Words: Victory/Doom/Defiance/Mercy) | Word of Ruin, Word of Legend |

### Phase C: Aspect Unique Mechanics + Cross-Pool Interactions (8 × 2 = 16 new talents)
Each aspect now has a **unique environmental interaction**, plus 8 cross-pool interaction talents (marked with †):

| Aspect | Unique Mechanic | New Talents |
|--------|----------------|-------------|
| Ore | **Geo-Armor** (temporary armor with diminishing returns) | Living Fortress† (Ore×Guardian), Seismic Fortress |
| Tide | **Pressure** (consecutive actions build burst damage + status) | Patient Predator† (Tide×Hunter), Tidal Surge |
| Pyre | **Burning Engine** (self-immolation as sustain, fire heals you) | Conflagration† (Pyre×Striker), Fuel the Inferno |
| Gale | **Reaction Economy** (extra reactions, Storm Charge from missed attacks) | Lightning Dance† (Gale×Skirmisher), Storm Strike |
| Radiance | **Aura Toggle** (3 switchable auras with passive + triggered effects) | Sacrifice Healing† (Radiance×Mender), Radiant Conduit |
| Shroud | **Shadow Debt** (damage seeds Shadow on targets, consume for spike) | Shadow Prison† (Shroud×Warden), Shadow Detonation |
| Anima | **Form Memory** (remember 3 beast forms, switch as 1 AP) | Beast Commander† (Anima×Speaker), Swift Shift |
| Aether | **Spell Weaving** (chain 2 spell schools for emergent combo effects) | Arcane Calculus† (Aether×Analyst), Resonance Cascade |

### Design Philosophy: Cross-Pool Interactions
The 8 cross-pool talents (†) are T3 talents in the Aspect pool that require a T2+ talent from a specific Archetype pool as prerequisite. This creates genuine build investment paths where your class combination (Aspect × Archetype) unlocks unique synergies no other class can access.

### Verb Category Distribution Shift

| Category | Before | After | Change |
|----------|--------|-------|--------|
| Numeric Modifier | 25.1% | ~18% | -7% |
| Conditional Trigger | 18.2% | ~24% | +6% |
| Mode Switch | 5.4% | ~9% | +4% |
| Resource Tradeoff | 1.0% | ~5% | +4% |
| Interaction Effect | 1.9% | ~6% | +4% |
| Restriction/Drawback | 0.5% | ~3% | +2.5% |
| Party Synergy | 5.8% | ~8% | +2% |

### Test Results
- All 22 tests pass (48.7s)
- Class Fantasy Audit: ALL 64 classes pass (min=6, max=70, avg=32.4 exclusive tropes)
- Total talents: 404 → 457 (+53 new talents)

---

## v4.5.3 (2026-02-07) — 368-Trope Class Fantasy Audit

### Class Fantasy Trope Audit (Test F1)

Created a comprehensive audit verifying each of the 64 classes can fulfill at least 5 distinct, recognizable fighting fantasy tropes from a library of **368 classic fighting styles** spanning 19 categories:

| Category | Count | Examples |
|----------|-------|---------|
| Blade Masters | 25 | Sword Saint, Kensei, Spell Blade |
| Crushing Force | 18 | Warhammer Lord, Juggernaut, One-Punch |
| Polearm & Axe | 14 | Dragoon, Viking Berserker, Spartan |
| Ranged Masters | 24 | Sniper, Fire Archer, Eldritch Sniper |
| Unarmed & Grappling | 18 | Martial Artist, Chi Master, Dragon Fist |
| Defensive Specialists | 24 | Iron Fortress, Sacred Shield, Void Shield |
| Berserkers & Rage | 16 | Berserker, Doom Slayer, Troll Blood |
| Assassins & Stealth | 20 | Shadow Assassin, Night Stalker, Soul Eater |
| Elemental Warriors | 28 | Pyromancer, Storm Lord, Elemental Avatar |
| Dark & Death | 24 | Death Knight, Lich, Vampire Lord |
| Holy & Divine | 20 | Paladin, Cleric, Valkyrie |
| Nature & Beast | 20 | Beastmaster, Shapeshifter, Spirit Walker |
| Arcane & Spell Combat | 20 | Battle Mage, Reality Warper, Enchanter |
| Commanders & Leaders | 20 | War Commander, Tyrant, Tactical Genius |
| Healers & Support | 20 | Divine Healer, Combat Medic, Phoenix |
| Hybrid Styles | 20 | Spell-Sword, Death Ranger, Thunder Monk |
| Mythological | 16 | Achilles, Ronin, Wuxia Hero |
| Crafters & Specialists | 12 | Alchemist, Golem Maker, Artificer |
| Anime/Gaming | 9 | Glass Cannon, Limit Breaker, Boss Killer |

**3-Gate Checking System:**
- Gate 1 (Stat Viability): Class has +2 to at least one required stat, or swap talent bridges gap
- Gate 2 (Form Access): Class form pool includes required form type
- Gate 3 (Talent Support): 3+ enabling talents accessible from class pools

**Exclusivity Filter:** A trope only "counts" if ≤16 of 64 classes (≤25%) can access it, ensuring class distinctness. Exclusive tropes must span ≥3 categories per class.

**Results:** ALL 64 classes pass (min=6, max=70, avg=32.4 exclusive tropes per class). Trope selectivity: 183 exclusive (1-8 classes), 74 selective (9-16), 110 broad (17-32), 1 generic (33-64). No fixes required — the talent and form system provides excellent fantasy coverage and class distinctness.

### Test Suite
- Added F1 (Class Fantasy Trope Audit) to test runner — now 22 tests total
- All 22 tests pass

## v4.5.2 (2026-02-07) — Mental→Melee & Spell+Sword

### Mental→Melee Aspect Pool Talents

Added 4 new T2 Aspect Pool talents allowing mental stats to drive melee attack rolls. Each has a unique secondary effect that rewards the class fantasy:

| Talent | Aspect | Stat | Prereq | Secondary Effect |
|--------|--------|------|--------|-----------------|
| SPELL-TEMPERED BLADE | Aether | INT 14+ | Arcane Strike | Target has disadvantage on spell saves |
| DARK INTENT | Shroud | WIL 14+ | Death's Touch | 2 necrotic/turn (stacks to WIL mod) |
| RIGHTEOUS STRIKE | Radiance | PRE 14+ | Inner Light | Gain 1 Composure on hit (1/round) |
| PREDATOR'S INSIGHT | Anima | WIS 14+ | Primal Instinct/Natural Attunement | Advantage on next Perception/Survival |

**Design Rationale:** Mental stats don't contribute to HP (formula: 20 + MIG×2 + FOR×2 + Lv×3), creating a natural HP tax (~18 HP at L10) that balances the stat swap. These are T2 talents requiring stat 14+, so they come online at L3-5 depending on investment.

### Spell+Sword Synergy Talents

**WAR CASTER (T2, Aether):** When you cast a spell and make a melee attack in the same turn, gain +2 to whichever you do second. Weapon can serve as spellcasting focus.

**SOUL STRIKE (T2, Shroud):** When you hit melee and cast shadow/death spell in the same turn: spell costs -1 Mana, melee ignores 2 armor. Melee kills grant +2 to next spell attack/DC.

### Class Scaling Breakpoints Added

Added explicit L10/L20/L30 scaling entries for three Aether classes:

**Magus (Aether×Skirmisher):**
- L10: Teleport 15m; cantrip → T1 spell; melee advantage after teleport
- L20: Bring ally; T2 spell; melee +INT mod damage within 1 round of casting
- L30: Teleport at will (free, 1/round); any spell during teleport; spell+melee = +1 AP

**Aegis (Aether×Guardian):**
- L10: Wall 15m; DEF bonus on first TWO attacks; wall blocks LoS
- L20: Dome (10m radius); allies inside +2 all saves
- L30: Selective permeability; DEF bonus on ALL attacks

**Spellbreaker (Aether×Warden):**
- L10: Dispel on touch; melee hits drain 2 Mana from casters
- L20: 5m silence zone; +4 vs magic; Counterspell free action
- L30: 10m antimagic zone; +WIL mod melee damage vs targets with active spells

### Mental-Primary Melee Class Audit

Audited all 16 classes with mental primary stats in melee roles:

| Stat | Classes | Talent Access | Status |
|------|---------|---------------|--------|
| INT | Battlemage, Magus, Aegis, Spellbreaker | Class feature + SPELL-TEMPERED BLADE + WAR CASTER | ✅ Fully supported |
| WIL | Reaper, Revenant, Assassin, Hexer | DARK INTENT + SOUL STRIKE | ✅ Fully supported |
| PRE | Paladin, Templar, Crusader, Beacon | RIGHTEOUS STRIKE | ✅ Fully supported |
| WIS | Savage, Prowler, Shaman | PREDATOR'S INSIGHT | ✅ Fully supported |

**Key Finding:** Hexer (WIL+4, no physical stats), Beacon (PRE+2/WIS+2/WIL+2, no physical stats), and Shaman (WIS+3/WIL+2, no physical stats) had zero melee-relevant stat bonuses before these talents. The new T2 talents are essential for their melee viability.

### Aspect Pool Talent Counts

| Aspect | Count | Change |
|--------|-------|--------|
| Aether | 20 | +2 (SPELL-TEMPERED BLADE, WAR CASTER) |
| Shroud | 20 | +2 (DARK INTENT, SOUL STRIKE) |
| Radiance | 19 | +1 (RIGHTEOUS STRIKE) |
| Anima | 19 | +1 (PREDATOR'S INSIGHT) |
| Ore, Tide, Pyre, Gale | 18 | unchanged |

### Files Modified

| File | Changes |
|------|---------|
| `references/talents-expanded.md` | 6 new T2 Aspect Pool talents (4 mental→melee + 2 spell+sword) |
| `references/classes.md` | L10/L20/L30 scaling for Magus, Aegis, Spellbreaker |

### Test Results (all 21 passing)

All balance tests verified after changes — no regressions.

---

## v4.5.1 (2026-02-06) — Balance Validation

### Automated Test Suite

Added 21 automated balance tests covering mathematical foundations, identity
differentiation, content viability, compression, stress testing, and scaling.

```
tests/
├── run_all_tests.py           # Test runner (discovers all test modules)
├── conftest.py                # Shared PC builders, combat sim, hit rate math
├── balance_test_a1.py         # Hit rate bands (58-72% at each level)
├── balance_test_a2.py         # Rounds-to-kill (4-7) and rounds-to-die (5-9)
├── balance_test_a3.py         # Stance non-triviality (no dominant stance)
├── balance_test_a4.py         # Resource depletion (25-45% remaining after 3 fights)
├── balance_test_a5.py         # Expert vs naive gap (expert advantage >= 15%)
├── identity_test_b1.py        # Archetype tactical signature (2+ clusters per aspect)
├── identity_test_b2.py        # Aspect variation (3+ distinct profiles per archetype)
├── identity_test_b3.py        # Fantasy trope legibility (7+ of 10 classes legible)
├── compression_test_c3.py     # Token budget (char < 500, combat < 800 tokens)
├── death_rate_test_d3.py      # Death rate calibration (L10: 5-40%, increasing)
├── scaling_cliff_test.py      # Full L1-10 sweep (no cliff in hit rate or RTK)
├── viability_test_e1.py       # 64-class multi-build (54+ classes with 2 viable builds)
├── viability_test_e2.py       # Talent pick rates (no must-picks > 65%, no dead < 2%)
├── viability_test_e3.py       # Form breadth (18+ of 20 forms accessible)
├── viability_test_e4.py       # Variant differentiation (2+ forms with distinct variants)
├── viability_test_e5.py       # Playstyle variety (7+ distinct playstyles)
├── viability_test_e6.py       # Solved path detection (6+ classes with unsolved paths)
├── cross_archetype_balance.py # DPR/survival ratio across all 8 archetypes
├── stress_test_munchkin.py    # Overpowered build check (hit < 95%, RTK > 2)
├── stress_test_useless.py     # Underpowered build check (DPR > 0.5, survives 3+ rounds)
├── stress_test_party.py       # Party composition viability (all > 20% win rate)
└── builds/
    ├── pyre_striker.py        # 3 Pyre/Striker mock builds
    ├── all_archetypes_pyre.py # All 8 archetypes with Pyre aspect
    └── atlas_128.json         # 128-build atlas (64 classes × 2 builds)
```

### Balance Changes Made During Testing

#### Enemy Formula Rebalance (creature.py)
- **HP formula:** `24 + level × 2` (was higher, caused RTK to exceed target band)
- **Damage formula:** `3 + level` (simplified from complex scaling)
- **Armor formula:** `level // 5` (was `level // 3`, reduced to prevent damage floor issues)
- **DEF unchanged:** `10 + level // 2` (validated by A1 hit rate tests)

#### Proficiency Bonus System Added (conftest.py)
- **Formula:** `(level + 1) // 3` applied to DAMAGE ONLY (not attack rolls)
- **Purpose:** Smooths DPR scaling so PC damage keeps pace with enemy HP growth
- **Values:** L1=0, L2-L4=1, L5-L7=2, L8-L10=3
- **Key insight:** Adding proficiency to attack rolls pushes focused builds above the A1 hit rate ceiling; damage-only proficiency scales DPR without breaking hit rate bands

### Key Findings

1. **2d6 staircase effect:** The discrete nature of 2d6 creates step-function hit rates. Each +1 modifier shifts hit rate by a full tier (~11% per step: 41.7% → 58.3% → 72.2% → 83.3%). This is inherent to the system and test target bands were aligned to natural 2d6 tiers.

2. **Archetype differentiation within same Aspect:** The system creates 2-3 stat clusters per aspect (not 8 distinct profiles). Full differentiation requires talent pools and form access, not stats alone. This is by design.

3. **Expert-naive divergence at high levels:** Naive L10 builds have only 16.7% effective hit rate vs focused builds at 83.3%. The gap (100-233%) is inherent to 2d6 + diminishing returns and is actually desirable — stat allocation should matter.

4. **Party combat at L5 is trivially easy:** All party compositions achieve 100% win rate against Elite + 2 Minions. Party encounters need harder tuning at mid levels.

5. **Token budget is excellent:** Character state = ~127 tokens, combat state = ~250 tokens. Well within 500/800 token budgets.

6. **Form breadth:** Medium Crush and Mounted Combat have 0 starting class access (unlockable only). All other 18 forms are accessible to multiple classes.

### Test Results Summary (all passing)
```
A1: Hit Rate Bands ................ PASS (58-83% across levels)
A2: Rounds-to-Kill ................ PASS (4-7 RTK, 5-9 RTD)
A3: Stance Non-Triviality ......... PASS (no dominant stance)
A4: Resource Depletion ............. PASS (25-45% remaining)
A5: Expert vs Naive Gap ........... PASS (advantage >= 15%, naive viable)
B1: Archetype Tactical Signature .. PASS (2+ clusters all 8 aspects)
B2: Aspect Variation .............. PASS (3+ distinct per archetype)
B3: Fantasy Trope Legibility ...... PASS (8/10 legible)
C3: Token Budget .................. PASS (127/250 tokens)
D3: Death Rate Calibration ........ PASS (L10: 18.5%, increasing)
Scaling Cliff ..................... PASS (no cliffs L1-L10)
E1: 64-Class Multi-Build .......... PASS (64/64 classes viable)
E2: Talent Pick Rates ............. PASS (no must-picks, no dead)
E3: Form Breadth .................. PASS (18/20 accessible)
E4: Variant Differentiation ....... PASS (3/3 forms differentiated)
E5: Playstyle Variety ............. PASS (10 distinct playstyles)
E6: Solved Path Detection ......... PASS (8/8 unsolved)
Cross-Archetype Balance ........... PASS (DPR 1.25x, Survival 1.33x)
Stress: Munchkin .................. PASS (hit 91.7%, win 99.9%)
Stress: Useless ................... PASS (DPR 2.2, survives 7 rounds)
Stress: Party ..................... PASS (all comps 100% win)
```

---

## v4.5 (2026-02-04)

### Major Changes

#### 1. Derived Stats Rebalanced
- **HP formula changed:** `20 + (MIG × 2) + (FOR × 2) + (Level × 3)`
  - Previously: `20 + (FOR × 3) + MIG + (Level × 2)`
  - FOR no longer dominates survivability (was 3× contribution, now 2×)
  - MIG now contributes equally to HP
  - Level scaling increased from ×2 to ×3
- **Stamina adjusted:** `10 + (FOR × 2) + AGI + Level`
  - Previously: `15 + (FOR × 2) + AGI + Level`
  - Base reduced from 15 to 10

#### 2. Composure Resource Added
- **New resource:** `10 + (PRE × 2) + WIL + Level`
- PRE finally has a resource pool it contributes to
- Uses:
  - Resist Intimidation, fear effects, social pressure
  - Rally allies (cost = ally count)
  - Inspire allies (grant bonus = Composure spent, max PRE mod)
- At 0 Composure: Disadvantage on social rolls, PRE abilities disabled
- Recovery: Short rest (PRE mod), Long rest (full)

#### 3. Attribute Caps Removed
- No more level-based caps (12 at L1-4, 14 at L5-9, etc.)
- Replaced with investment cost scaling:
  - 10-14: 1 point per +1
  - 15-18: 2 points per +1
  - 19-22: 3 points per +1
  - 23-26: 4 points per +1
  - 27-30: 5 points per +1
- Bonuses from Aspect/Archetype/Background now stack freely

#### 4. Attribute Points Doubled
- Base: +2 points per level (was +1)
- Milestone bonus: +1 additional at L5/10/15/20/25/30
- Total by L30: 64 points (was ~36)
- Enables deeper specialization with diminishing returns

#### 5. Proficiency Talents Tiered
Three tiers replace the old flat Attr 12+ requirement:

**Open Proficiency (Attr 10+):**
- Attack OR damage swap only
- Examples: Martial Arts, Careful Aim, Brutal Swing

**Standard Proficiency (Attr 14+):**
- Attack AND damage swap
- Examples: Surgical Precision, Flowing Steel, Instinctive Archer

**Mastery Proficiency (Attr 18+):**
- Build-defining effects
- Examples: Mind Over Matter, Perfect Form, Transcendent Technique

#### 6. Spell Tier Level Requirements
| Tier | Attr Req | Level Req | Mana Cost |
|------|----------|-----------|-----------|
| 0 | — | — | 0 |
| 1 | 12+ | — | 2-3 |
| 2 | 14+ | 3+ | 4-6 |
| 3 | 16+ | 7+ | 8-10 |
| 4 | 18+ | 12+ | 12-15 |
| 5 | 20+ | 18+ | 18-22 |
| 6 | 24+ | 25+ | 25+ |

- Prevents early-game attribute stacking from bypassing progression
- L4 casters can now access Tier 2 spells (was impossible with 12 cap)

#### 7. Overcasting Rules Added
Characters may cast one tier above qualification:
- Mana cost doubled
- Disadvantage on all spell attack rolls and effect DCs
- On failure: 1d6 psychic damage per tier overcast

#### 8. Magic Type Mapping Complete
All 20 magic schools now assigned to types:
- **Arcane (INT):** Fire, Water/Ice, Lightning, Wind, Metal, Force, Time
- **Divine (WIS):** Light, Healing, Warding
- **Primal (WIS):** Beast/Nature, Plant, Spirit (if chosen)
- **Blood (WIL):** Blood, Death
- **Psionic (WIL):** Mind, Shadow (if chosen)
- **Dual-type forms:** Earth, Shadow, Spirit, Illusion require permanent choice at acquisition

#### 9. Awakening Passive Categories
Two categories based on activation reliability:

**Consistent Passives (always active):**
- Design target: +2-4 effective stat equivalent at L1
- Examples: DR on first hit, permanent initiative bonus, condition immunity
- Knight's Iron Resolve, Oracle's Foresight

**Conditional Passives (requires trigger):**
- Design target: +4-8 effective stat equivalent when active
- Examples: Heal on kill, bonus from stealth, bonus when wounded
- Reaper's Death's Harvest, Assassin's Death's Shadow

**Scaling Pattern:**
- L1: Base effect
- L10: Effect doubles OR new application
- L20: Effect doubles again OR significant capability
- L30: Build-defining ultimate

#### 10. Stances Expanded
| Stance | AP | Move | ATK | DEF | DMG | Special |
|--------|-----|------|-----|-----|-----|---------|
| Balanced | 3 | +0 | +0 | +0 | +0 | Default |
| Aggressive | 4 | +0 | +2 | -2 | +2 | Bonus damage all types |
| Defensive | 2 | -2m | -2 | +4 | +0 | Cannot be crit |
| Mobile | 3 | +4m | +0 | +0 | +0 | Free disengage, no OA |
| Focused | 2 | 0m | Adv | -2 | +0 | Cannot move |

- Change at start of turn only (free action)
- Prone/Grappled/Stunned forces Balanced
- Special stances (Berserker, Iron Wall, etc.) unlock via talents/evolutions

#### 11. Techniques as Examples
- Added header to all three forms files
- ~1,200 techniques are representative examples, not exhaustive
- GMs may create additional following power budget in core-balance-templates.md
- Players may propose custom techniques (GM approval, must discover in-world)

### Files Modified

| File | Changes |
|------|---------|
| `creation.md` | Updated derived stats table, Marcus Chen example |
| `character.py` | New formulas, Composure, removed caps |
| `attributes-core.md` | Replaced caps with investment costs |
| `progression.md` | +2 points/level, updated tables |
| `talents-expanded.md` | Three-tier proficiency system |
| `magic.md` | Level requirements, overcasting, type mapping |
| `classes.md` | Awakening categories, L10/20/30 scaling |
| `combat.md` | Expanded stances section |
| `forms-combat-expanded.md` | Techniques as Examples header |
| `forms-magic-expanded.md` | Techniques as Examples header |
| `forms-utility-expanded.md` | Techniques as Examples header |
| `SKILL.md` | Updated formulas, stances table, v4.5 summary |

### Design Rationale

1. **FOR dominance fix:** FOR contributed 3× to HP, making it the only stat that mattered for survivability. Splitting with MIG creates build diversity.

2. **PRE contribution:** PRE had no resource pool, making it feel incomplete compared to other stats. Composure fills this gap with meaningful social/morale mechanics.

3. **Caps → Costs:** Hard caps felt arbitrary and punished focused builds. Diminishing returns via investment costs rewards breadth while allowing depth.

4. **Proficiency tiers:** All T1 proficiency talents required Attr 12+, but L1 cap was 12. This created class imbalance. Three tiers with escalating power fix this.

5. **Spell level gates:** Tier 2 required Attr 14, but L1-4 cap was 12. L4 casters couldn't cast Tier 2 spells. Level gates ensure progression feels earned.

6. **Awakening categories:** Passives had wildly different reliability (always-on vs. kill trigger vs. stealth). Explicit categories help balance and set player expectations.

---

## v4.4 (Previous)

- Initial procedural generation system
- 64 authored classes
- 60 form trees with 1,200 techniques
- Clock system implementation
- Comprehensive evaluation framework

---

## v4.0 (Foundation)

- Core mechanics established
- 2d6 resolution system
- 8 Aspects × 8 Archetypes matrix
- Discovery-based progression
