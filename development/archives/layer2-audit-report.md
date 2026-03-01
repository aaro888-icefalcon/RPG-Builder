# Layer 2 Audit Report — Resource Economy & Equipment/Crafting

**Version:** v4.5.9 post-Layer 1 rebalance
**Date:** 2026-02-08
**Scope:** Resource pools (HP/Stamina/Mana/Composure), recovery economy, equipment scaling, crafting/loot, survival integration

---

## Executive Summary

| System | Status | Summary |
|--------|--------|---------|
| **HP** | HEALTHY | Scales appropriately; 1v1 standard fights cost 13-26% HP — correct for 3-fight adventuring day |
| **Stamina** | NEEDS TUNING | Goes negative on fight 3 of a standard martial rotation; recovery (50% short rest) insufficient for sustained technique usage |
| **Mana** | HEALTHY | 50% short rest recovery is generous; casters sustain 3+ fights trivially at mixed T1/T2 rotations |
| **Composure** | UNDERSPECIFIED | Pool is large relative to incoming damage (8-12 fear hits to Shaken); composure-as-offense (Speaker actions) is well-costed but rarely pressured |
| **Equipment ATK** | HEALTHY | v4.5.9 weapon tier ATK bonuses solve the PC-vs-DEF scaling collapse from Layer 1 |
| **Equipment DEF** | CAUTION | Armor tier scaling is exponential (T4/T5 give +4/+6 bonus on top of base) — tank builds become unhittable; enemies have no way to pierce |
| **Crafting** | MISSING | No crafting system exists. Referenced in `skills-common.md` and `character.py` affinities but unimplemented |
| **Loot Economy** | HEALTHY | Scarcity is well-enforced; progression from T1→T2 takes ~14 sessions via loot alone |
| **Survival Economy** | STUB | Food/water/ammo rules exist in `scarcity.md` but have no mechanical integration with combat resources |
| **AI State Tracking** | PARTIAL | HP/conditions tracked well; stamina/mana depletion NOT tracked in combat state; no rest economy tracking |

---

## Step 0: Discovery Maps

### Resource Map

| Resource | Formula | Source File | Recovery Rule | Source |
|----------|---------|-------------|---------------|--------|
| HP | `20 + (MIG×2) + (FOR×2) + (Lv×3)` | `character.py:272` | Short: 0%, Long: 100% | `conditions.md:189-198` |
| Stamina | `10 + (FOR×2) + AGI + Lv` | `character.py:273` | Short: 50%, Long: 100% | `conditions.md:189-198` |
| Mana | `10 + (INT×2) + (WIL×2) + Lv` | `character.py:274` | Short: 50%, Long: 100% | `conditions.md:189-198` |
| Composure | `10 + (PRE×2) + WIL + Lv` | `character.py:276` | Short: 50%, Long: 100% | `conditions.md:126-134` |

**Key:** All resource formulas use attribute SCORES (×2 multiplier), not modifiers. This means resource pools are dominated by attribute investment, not level scaling (+3 HP/level vs +2 HP per point of MIG or FOR).

### Equipment Map

| Slot | Scaling | Source File | Missing |
|------|---------|-------------|---------|
| Weapon | Base DMG + Tier DMG + Tier ATK | `equipment.md:48-54` | No crafting path to create/upgrade |
| Armor | Base DEF + Tier DEF bonus | `equipment.md:94-100` | No repair/degradation system |
| Shield | Flat +1/+2 DEF | `equipment.md:80-81` | No scaling with tier |
| Consumables | Flat healing/effects | `scarcity.md:64-73` | No mechanical integration with combat scripts |

---

## Audit A: Resource Economy

### A1: Resource Budget Tables

#### HP by Build Archetype

| Level | Martial | Caster | Social | Tank |
|-------|---------|--------|--------|------|
| 1 | 85 | 63 | 63 | 83 |
| 5 | 109 | 75 | 75 | 107 |
| 10 | 132 | 94 | 94 | 130 |
| 15 | 155 | 109 | 109 | 153 |
| 20 | 178 | 128 | 128 | 176 |

**Observation:** Martial and Tank HP are ~40-50% higher than Caster/Social at all levels. This is intentional — MIG/FOR investment drives HP. The gap is consistent and creates meaningful archetype differentiation.

**HP Pressure per Standard Fight (4 rounds, 1v1 vs at-level standard enemy):**

| Level | Enemy DPR | 4-Round Damage | Martial HP Lost | Caster HP Lost |
|-------|-----------|----------------|-----------------|----------------|
| 1 | 4.7 | 19 | 22% | 30% |
| 5 | 4.4 | 18 | 16% | 24% |
| 10 | 4.3 | 17 | 13% | 18% |
| 15 | 10.0 | 40 | 26% | 37% |
| 20 | 12.8 | 51 | 29% | 40% |

**Target from `hard-rules.md`:** "4-round combat should leave a martial at 40-60% stamina" and `math-assumptions.md` says "4-round standard fight: enemy depletes 30-50% HP."

**Finding:** Solo standard enemies deplete only 13-29% of martial HP. This is BELOW the 30-50% target. However, encounters are designed to be group-based (2-4 enemies); group encounters would correctly reach the 30-50% band. The math-assumptions document should clarify that 30-50% applies to GROUP encounters, not 1v1.

#### Stamina by Build Archetype

| Level | Martial | Caster | Social | Tank |
|-------|---------|--------|--------|------|
| 1 | 47 | 41 | 41 | 57 |
| 5 | 57 | 45 | 45 | 69 |
| 10 | 68 | 56 | 56 | 80 |
| 15 | 77 | 61 | 61 | 89 |
| 20 | 88 | 72 | 72 | 100 |

**Stamina Budget — Martial L5 (57 Stamina):**

| Rotation | Cost/Round | 4 Rounds | % Pool | With Reactions (+8) |
|----------|-----------|----------|--------|---------------------|
| All T1 (3×2 stam) | 6 | 24 | 42% | 56% |
| Mixed (1×T2 + 2×T1) | 8 | 32 | 56% | 70% |
| Heavy T2 (2×T2 + 1×T1) | 12 | 48 | 84% | 98% |
| T3 Burst (2×T3 + 10×T1) | — | 34 | 60% | 74% |

**3-Fight Adventuring Day (Mixed rotation + reactions = 40 stam/fight):**

| Phase | Stamina | % Pool |
|-------|---------|--------|
| Start | 57 | 100% |
| After Fight 1 | 17 | 30% |
| Short Rest (+28) | 45 | 79% |
| After Fight 2 | 5 | 9% |
| Short Rest (+28) | 33 | 58% |
| After Fight 3 | **-7** | **-12%** |

**Finding: STAMINA GOES NEGATIVE.** A martial using a mixed T1/T2 rotation with reactions cannot sustain 3 fights with 2 short rests. By fight 3, they have exhausted their pool entirely and must downgrade to basic attacks or skip technique usage. This matches the `hard-rules.md` intent ("Stamina should matter") but the hard-rules also say "4-round combat should leave a martial at 40-60% stamina" — which only holds for fight 1, not fights 2-3.

#### Mana Budget — Caster L5 (85 Mana)

| Rotation | Cost/Round | 4 Rounds | % Pool |
|----------|-----------|----------|--------|
| All T1 (2×3 mana) | 6 | 24 | 28% |
| Mixed (1×T1 + 1×T2) | 8 | 32 | 38% |
| All T2 (2×5 mana) | 10 | 40 | 47% |

**3-Fight Adventuring Day (Mixed rotation = 32 mana/fight):**

| Phase | Mana | % Pool |
|-------|------|--------|
| Start | 85 | 100% |
| After Fight 1 | 53 | 62% |
| Short Rest (+42) | 85 | 100% |
| After Fight 2 | 53 | 62% |
| Short Rest (+42) | 85 | 100% |
| After Fight 3 | 53 | 62% |

**Finding: MANA NEVER DEPLETES.** Casters at L5 with 85 mana recover to full after every short rest because recovery (42) > spend (32). Even with all-T2 rotation (40/fight), short rest still brings them to 87 → 85 (capped). The `hard-rules.md` target of "3 combats should drain a caster to ~20% mana" is **never achieved** with the current mana pool sizes and 50% short rest recovery.

**Root cause:** Mana pool uses TWO ×2 multipliers (INT×2 + WIL×2) while Stamina uses only one (FOR×2). A caster with INT 20, WIL 15 gets `10 + 40 + 30 + 5 = 85`, while a martial with FOR 15, AGI 12 gets `10 + 30 + 12 + 5 = 57`. Mana is 49% larger than Stamina despite serving equivalent roles.

#### Composure Budget

| Build | L5 Pool | Fear Hits to Shaken (50%) | Fear Hits to Broken (0%) | Actions Available |
|-------|---------|---------------------------|--------------------------|-------------------|
| Social | 71 | 12 | 24 | 35 Demoralize |
| Martial | 48 | 8 | 16 | 24 Demoralize |

**Finding:** Composure is extremely durable relative to incoming damage. Fear effects deal 2-4 damage per source (avg 3). A non-social build needs 8 fear hits to reach Shaken — this rarely happens in play because few enemies have fear auras and each Fear Aura triggers once per turn with a WIL save. Composure is currently more of a Speaker offensive resource than a shared survival resource.

### A2: Recovery Economy

| Resource | Short Rest (1hr) | Long Rest (8hr) | In-Combat Recovery | Source |
|----------|-----------------|-----------------|--------------------|---------|
| HP | 0% | 100% | Bandage (1d6, 1/combat), healing techniques | `conditions.md:189-198` |
| Stamina | 50% of MAX | 100% | None documented | `conditions.md:189-198` |
| Mana | 50% of MAX | 100% | None documented | `conditions.md:189-198` |
| Composure | 50% of MAX | 100% | Rally (+PRE mod), kill frightening enemy (full) | `conditions.md:126-134` |

**Critical gap:** HP has ZERO short rest recovery. The only in-field HP recovery is First Aid (Bandage: 1d6, once per combat — `conditions.md:183`). Over a 3-fight day, HP attrition is the PRIMARY resource pressure, not Stamina or Mana. This creates a sharp asymmetry:

- **Martials:** Stamina depletes (fight 3 negative), HP depletes moderately (30-60% over 3 fights), Mana irrelevant
- **Casters:** Mana never depletes, HP depletes MORE (lower pool), Stamina minimal use

The system punishes martials via stamina while casters face no equivalent pressure. The `hard-rules.md` intent says both should feel resource pressure, but the numbers don't support it for casters.

### A3: Cross-Resource Pressure

**Condition interactions that drain multiple resources:**

| Condition | HP Drain | Stamina/Mana Drain | Composure Drain | Source |
|-----------|----------|--------------------|-----------------|--------|
| Bleeding | 2/round | — | — | `conditions.py:12-20` |
| Burning | 3/round | — | — | `conditions.py:22-29` |
| Poisoned | 2/round + -2 all rolls | — | — | `conditions.py:38-46` |
| Exhausted | — | -2 physical (indirect: waste AP) | — | `conditions.py:63-69` |
| Mana Drained | — | — (cannot cast) | — | `conditions.py:163-169` |
| Frightened | — | — | 2-4 per source | `conditions.md:109-113` |
| Broken (Comp=0) | — | — | -4 all rolls (cascading) | `conditions.py:205-212` |

**Finding:** Cross-resource pressure is WEAK. No condition drains both HP and Stamina/Mana simultaneously. The Exhausted condition (-2 physical, half movement) doesn't drain stamina faster — it just makes actions worse. There's no "spending HP to power techniques" or "mana burn" mechanic that creates interesting tradeoffs between pools.

The Composure→combat penalty cascade (Shaken→Rattled→Wavering→Broken) is the strongest cross-resource interaction, but it only affects social/mental rolls until Wavering (-2 all rolls) or Broken (-4 all rolls).

### A4: Scaling Coherence

**Resource Pool Growth Rates:**

| Resource | L1→L20 Growth | Growth Per Level | Dominant Term |
|----------|---------------|-----------------|---------------|
| HP (Martial) | 85→178 | +4.9/level | MIG/FOR scores (fixed) >> Lv×3 |
| HP (Caster) | 63→128 | +3.4/level | Lv×3 dominates (low MIG/FOR) |
| Stamina | 47→88 | +2.2/level | FOR score (fixed) >> Lv×1 |
| Mana | 69→124 | +2.9/level | INT/WIL scores >> Lv×1 |
| Composure | 57→104 | +2.5/level | PRE score >> Lv×1 |

**Enemy Damage Growth:** DMG = 3 + level → +1/level (linear)

**Technique Cost Growth:** T1=2-3, T2=4-6, T3=7-10 (constant, not level-scaled)

**Finding:** Resource pools grow faster than drain rates because the attribute-score-based base is large and fixed while level scaling (+1/level for most pools, +3/level for HP) adds slowly. This means:
- **HP safety margin increases** with level (enemy DPR grows linearly but HP pool has a large constant base)
- **Stamina/Mana budgets are essentially level-independent** — technique costs don't scale with level, so the same rotation costs the same absolute amount whether you're L5 or L20. The extra stamina from leveling just provides more buffer, making high-level fights LESS resource-pressured than low-level fights.

**Design question:** Should technique costs scale with level, or should higher-tier techniques (which become available at higher levels) provide the cost escalation naturally?

### A5: AI State Tracking

**Currently tracked in `combat.py` `create_entity_state()`:**

| Field | PC | NPC | Creature | Status |
|-------|-----|-----|----------|--------|
| HP (current/max) | ✓ | ✓ | ✓ | Full tracking |
| Stamina (current/max) | ✓ | ✓ | None | **Tracked but never decremented in combat script** |
| Mana (current/max) | ✓ | ✓ | None | **Tracked but never decremented in combat script** |
| Composure (current/max) | ✓ | ✓ | None | **Tracked but never decremented in combat script** |
| Conditions | ✓ | ✓ | ✓ | Array of condition entries |
| Behavior tree | None | ✓ | ✓ | For AI decision-making |
| Turn state | ✓ | ✓ | ✓ | Technique tracking, repetition penalty |
| Combat state | ✓ | ✓ | ✓ | Second wind flag only |

**Critical gap:** `combat.py` tracks Stamina/Mana/Composure as state fields but the `attack_roll()` function NEVER checks or decrements them. There is no enforcement of technique costs in the combat script — it's assumed the AI-GM will manually track these. This means:

1. No script validates "does this PC have enough stamina for Power Strike?"
2. No script reduces mana when a spell is cast
3. NPC behavior trees don't consider their own resource pools when selecting actions
4. The `format_combat_state()` function displays stamina/mana but doesn't warn when low

**Recommendation:** Either add resource cost validation to the combat system, or explicitly document that resource tracking is the AI-GM's responsibility with clear tracking format.

**Condition complexity budget** (`conditions.md:76`): "Max 3-5 conditions per target, max 8 total across battlefield" — this is well-defined and appropriate for AI state management.

---

## Audit B: Equipment & Crafting

### B1: Equipment Impact on Combat Math

**Weapon contribution to total damage:**

| Level | Weapon (base+tier) | Attr Mod | Weapon % of Total |
|-------|-------------------|----------|-------------------|
| 1 | 8+0 = 8 | +2 | 80% |
| 5 | 8+2 = 10 | +4 | 71% |
| 10 | 8+4 = 12 | +5 | 71% |
| 15 | 8+6 = 14 | +6 | 70% |
| 20 | 8+8 = 16 | +7 | 70% |

Weapon provides 70-80% of total per-hit damage. This is by design — equipment matters. The v4.5.9 ATK bonus on weapons (T1=+0, T2=+1, T3=+2, T4=+3, T5=+4) successfully closes the ATK-vs-DEF gap that Layer 1 identified.

**Armor contribution to total DEF:**

| Level | Armor DEF | AGI Mod | Total DEF | Armor % |
|-------|-----------|---------|-----------|---------|
| 1 | +0 | +0 | 10 | 0% |
| 5 | +3 | +1 | 14 | 21% |
| 10 | +4 | +2 | 16 | 25% |
| 15 | +5 | +2 | 17 | 29% |
| 20 | +6 | +3 | 19 | 32% |

Armor is 0-32% of DEF for average builds. The base 10 DEF is the dominant term at all levels. This means armor upgrades provide MARGINAL defense improvements, while the base 10 provides a consistent floor.

### B2: Equipment Scaling Across Tiers

**Weapon Tier Scaling (from `equipment.md:48-54`):**

| Transition | DMG Increase | ATK Increase | Requirement Increase |
|-----------|-------------|-------------|---------------------|
| T1→T2 | +2 | +1 | +2 attr |
| T2→T3 | +2 | +1 | +2 attr |
| T3→T4 | +2 | +1 | +2 attr |
| T4→T5 | +2 | +1 | +2 attr |

**Finding:** Weapon scaling is LINEAR and consistent. Each tier adds the same +2 DMG and +1 ATK. The attribute requirement increase (+2 per tier) is also linear. This is clean design — no exponential power spikes.

**Armor Tier Scaling (from `equipment.md:94-100`):**

| Transition | DEF Increase |
|-----------|-------------|
| T1→T2 | +1 |
| T2→T3 | +1 |
| T3→T4 | **+2** |
| T4→T5 | **+2** |

**Finding: ARMOR SCALING IS EXPONENTIAL at high tiers.** T3→T4 and T4→T5 each add +2 DEF instead of +1. Combined with base armor type:

| Armor | T1 | T3 | T5 | Spread |
|-------|----|----|----|----|
| Light | +2 | +4 | +8 | 6 |
| Medium | +4 | +6 | +10 | 6 |
| Heavy | +6 | +8 | +12 | 6 |

Heavy armor T5 gives +12 DEF. With base 10, AGI mod +3, shield +2, Shield talent +3: DEF = 10+3+12+2+3 = **30**. Enemy ATK at L20 = +11. Need 19+ on 2d6 — **impossible**. Even legendary enemies (+4 ATK = +15) need 15+ — **impossible**.

This is the same tank invulnerability issue identified in the Layer 1 plan but now quantified. It's acceptable for T5 to be absurdly rare (L20+, Legendary items), but the T4 problem is real:

Heavy T4 (+10) + shield (+2) + talents (+3) + AGI (+3) = DEF 28 at L15. Boss enemy ATK at L15 = 9+3 = +12. Need 16+ — impossible. Even legendary (+4) = +13, need 15+ — impossible.

**Severity: Moderate.** Tank builds in T4+ armor are functionally immortal against even boss enemies. This doesn't break the game because T4 armor requires FOR 20 + MIG 18 (achievable around L15-18), but it removes all threat from physical attacks.

### B3: Crafting System

**Status: DOES NOT EXIST.**

Evidence of intended crafting:
- `character.py:18`: Ore aspect has `"affinities": ["defense", "physical", "crafting"]`
- `skills-common.md`: Contains crafting-related skills (referenced in System & Magic arena)
- `scarcity.md:103-104`: Crystal (raw: 20-50 credits, refined: 100+) suggests refinement process
- `gm-protocol.md`: "System & Magic" move arena covers crafting checks

**What's missing:**
1. No recipe system
2. No material → equipment conversion rules
3. No repair/degradation mechanics
4. No crafting DC table
5. No crafting time requirements
6. No relationship between gathered materials and equipment tiers
7. No skill-based crafting modifiers

**Impact:** Players cannot create or upgrade equipment through gameplay. Equipment acquisition is entirely via loot drops and purchases. This is consistent with the scarcity philosophy ("this is not a power fantasy") but limits player agency for builds that invest in crafting-related attributes/skills.

### B4: Survival Economy Integration

**Documented rules (`scarcity.md:129-148`):**

| Need | Requirement | Penalty | Death |
|------|-------------|---------|-------|
| Food | 1/day | -1 all rolls/day (max -4) | 7 days |
| Water | 1/2 days | -2 all rolls/day (max -6) | 4 days |
| Ammunition | Track individually | Run out | — |
| Medicine | Finite supply | No healing | — |

**Finding: SURVIVAL RESOURCES HAVE NO MECHANICAL INTEGRATION.**

1. No script tracks food/water/ammo
2. No condition in `conditions.py` for starvation/dehydration (only "Exhausted" which requires long rest, not food)
3. No inventory system in `combat.py` or `character.py` that counts consumables
4. Survival penalties (-1/-2 per day) are documented but never enforced by scripts
5. No connection between survival resources and combat resources (e.g., "can't long rest without food" is implied but not codified)

The survival economy exists entirely in narrative rules (`scarcity.md`, `hard-rules.md`) with no mechanical backing. The AI-GM must track all survival state manually.

### B5: Equipment AI State Tracking

**Currently tracked:**

| Data | Where | Format |
|------|-------|--------|
| Weapon base damage | `create_entity_state()`: `weapon_base` | Integer |
| Armor value | `create_entity_state()`: `armor` | Integer (damage reduction) |
| Weapon tier ATK bonus | Folded into `attack_mod` | Not separately tracked |
| Weapon tier DMG bonus | Folded into `damage_mod` or `weapon_base` | Not separately tracked |
| Equipment list | Not tracked | — |
| Consumable inventory | Not tracked | — |
| Equipment condition | Not tracked | — |

**Finding:** Equipment is reduced to two numbers (weapon_base, armor) in combat state. The AI-GM cannot distinguish "Iron Greatsword" from "Runed Greatsword" in the combat schema — both are just `weapon_base: X`. This is acceptable for combat resolution but loses information needed for:
- Loot decisions ("is this upgrade worth equipping?")
- Equipment-based ability triggers (T3+ weapons have special abilities)
- Inventory management

---

## Cross-Audit Dependencies

### D1: Resource ↔ Equipment Interactions

| Interaction | Status | Notes |
|-------------|--------|-------|
| Weapon DMG → HP damage | Working | `attack_roll()` uses weapon_base + damage_mod |
| Armor → HP protection | Working | `attack_roll()` subtracts armor from final damage |
| Weapon tier → ATK bonus | Working (v4.5.9) | ATK mod includes weapon tier bonus |
| Equipment → Stamina/Mana cost | **Missing** | No equipment affects technique costs |
| Equipment → Resource recovery | **Missing** | No equipment grants HP/Stamina/Mana recovery |
| Equipment repair → Economy | **Missing** | No durability/repair system |

**Gap:** Equipment is purely offensive/defensive. No equipment interacts with resource economies (no "staff that reduces mana costs by 1" or "armor that recovers 2 stamina/round"). This limits equipment design space.

### D2: Dependencies on In-Progress Systems

| System | Dependency | Current State | Impact |
|--------|-----------|---------------|--------|
| **Advancement (progression.md)** | Attribute growth drives resource pools | Defined | Resource pools are predictable |
| **Talents (talents-expanded.md)** | Survivability tree adds HP (+8/+20/+35/+50) | Defined | HP analysis should include talent HP; adds 5-30% to martial HP |
| **Forms (forms-combat-expanded.md)** | Technique costs drive stamina/mana budgets | Defined | Costs are the source data for budget analysis above |
| **Chargen redesign** | Starting attributes set initial resource pools | In-progress | May shift L1 numbers significantly |
| **Crafting** | Would create equipment acquisition path | Missing | Currently no impact (doesn't exist) |
| **Skill system (skills-common.md)** | Skills have stamina/mana costs | Defined | Adds to combat resource drain but not analyzed in combat scripts |

**Key dependency:** The Survivability talent tree (Tough→Tougher→Unkillable→Deathless) adds up to +50 HP. For a martial at L10 with Unkillable (T3, +35 HP): 132+35 = 167 HP. This significantly affects HP budget calculations. The audit tables above do NOT include talent HP — actual play HP will be 10-30% higher for builds that invest in survivability.

### D3: Survival Loop Coherence

**Intended loop (from `hard-rules.md`):**
```
3 combats → short rest → 3 combats → long rest
Resource pressure builds across fights
Loot is rare; equipment upgrades are meaningful milestones
Food/water/medicine are finite; scarcity creates tension
```

**Actual loop (from math):**
```
Fight 1: HP -22%, Stamina -70%, Mana -38%
Short rest: HP unchanged, Stamina → 79%, Mana → 100%
Fight 2: HP -44% cumulative, Stamina → 9%, Mana → 62%
Short rest: HP unchanged, Stamina → 58%, Mana → 100%
Fight 3: HP -66% cumulative, Stamina → NEGATIVE, Mana → 62%
Long rest: Everything → 100%
```

**Incoherence:**
1. **HP is the real attrition resource** — no short rest recovery, cumulative pressure works
2. **Stamina creates fight-3 crisis** — martials can't use techniques by fight 3
3. **Mana is a non-issue** — casters never feel resource pressure
4. **Food/water/medicine exist on paper only** — no scripts enforce them

The survival loop partially works (HP pressure is correct, stamina pressure is severe) but is asymmetric between martials and casters.

---

## Detailed Findings

### Finding 1: Stamina-Mana Asymmetry — ADDRESSED (v4.5.10)

- **Severity:** HIGH
- **Resolution:** Mana formula changed to `10 + (INT×2) + WIL + Lv`. Mana short rest recovery reduced to 33%. L5 caster mana 79→65, 3-fight budget now depletes to ~17%.
- **Area:** Resource Economy (A1, A2)
- **Evidence:** Martial Stamina L5=57, Caster Mana L5=85. Mixed T1/T2 rotation costs 32-40 per fight. Stamina goes negative by fight 3; Mana never drops below 62%.
- **Root Cause:** Mana formula uses TWO ×2 multiplied attributes (INT×2 + WIL×2 = up to 74 base) while Stamina uses ONE ×2 plus ONE ×1 (FOR×2 + AGI×1 = up to 44 base). The ×2/×1 vs ×2/×2 asymmetry creates a ~49% pool size advantage for Mana.
- **Impact:** Casters face no meaningful resource pressure in a standard adventuring day. Martials are forced to downgrade to basic attacks by fight 3. This violates the `hard-rules.md` pacing target ("3 combats should drain a caster to ~20% mana").
- **Recommendation:** Either (a) increase Stamina formula to `10 + (FOR×2) + (AGI×2) + Lv` for parity, or (b) decrease Mana formula to `10 + (INT×2) + WIL + Lv`, or (c) reduce mana short rest recovery to 25%, or (d) increase spell mana costs by ~50%.
- **Dependencies:** Changing Stamina formula affects Tank builds (FOR×2 is already double-counted with HP). Changing Mana formula affects all caster balance.
- **Design Decision Required:** YES — this is a deliberate asymmetry or a bug.

### Finding 2: HP Has No Short Rest Recovery

- **Severity:** MODERATE
- **Area:** Recovery Economy (A2)
- **Evidence:** `conditions.md:189-193`: Short rest recovers 50% Stamina, 50% Mana, 50% Composure, 0% HP. Only in-combat healing (Bandage: 1d6 once, healing techniques) provides HP recovery.
- **Impact:** HP is the only resource with no passive recovery mechanism. Over a 3-fight day, cumulative HP loss (40-66%) is the primary death risk. This creates correct tension for the survival tone, but means that parties without a Mender (healer archetype) face significantly harder attrition.
- **Recommendation:** This appears intentional for the survival tone. However, consider documenting "First Aid: Treat Wounds (DC 11, 1 hour, heal FOR mod × 2 HP)" as a short rest activity to give non-healer parties a slow recovery option. This exists partially in First Aid rules but without a short-rest-specific healing action.
- **Design Decision Required:** NO — working as intended for survival tone, but could use a codified short-rest healing option.

### Finding 3: Armor Tier Scaling Creates Invulnerable Tanks — ADDRESSED (v4.5.10)

- **Severity:** MODERATE
- **Resolution:** Armor tier bonus flattened to +1/tier across all tiers (T4: +4→+3, T5: +6→+4). Tank DEF ceiling reduced by 1-2 points at T4/T5. Core tank immunity issue noted for Layer 3.
- **Area:** Equipment Scaling (B2)
- **Evidence:** Heavy T4 armor (+10 DEF) + shield (+2) + Shield talent T3 (+3) + AGI mod (+3) = DEF 28. Boss enemy ATK at L15 = +12. Need 16+ on 2d6 — impossible (max roll = 12+modifier). Even legendary enemies (+15 ATK) need 13+ → 0% hit.
- **Root Cause:** Armor tier bonus jumps from +1/tier to +2/tier at T4-T5. Combined with shield and talent stacking, total DEF exceeds the 2d6 resolution ceiling.
- **Impact:** Tank builds in T4+ heavy armor are physically untouchable. This may be intentional ("fantasy of the impregnable knight") but removes mechanical tension from physical combat for these builds. Bosses would need special abilities (ignore armor, target mental DEF) to threaten tanks.
- **Recommendation:** Either (a) flatten armor tier bonus to +1/tier across all tiers, (b) add armor penetration to elite/boss enemies, or (c) accept this as a feature and ensure boss/legendary encounters include mental/magical attacks. Option (c) is likely correct given the system's design philosophy.
- **Design Decision Required:** YES — is tank physical invulnerability intended at T4+?

### Finding 4: No Crafting System Exists

- **Severity:** MODERATE
- **Area:** Equipment & Crafting (B3)
- **Evidence:** `character.py:18` references "crafting" affinity for Ore aspect. `skills-common.md` has crafting skills. `scarcity.md` prices crystal (raw/refined). But no crafting rules, recipes, DCs, or material requirements exist anywhere in the codebase.
- **Impact:** Equipment acquisition is limited to loot drops (slow — 14 sessions per uncommon) and purchases (requires credits). Builds that invest in crafting-related attributes have no mechanical return. The Ore/Artificer class fantasy is partially unfulfilled.
- **Recommendation:** Create a minimal crafting framework: materials + DC check + time = equipment. Tie to the "System & Magic" move arena already referenced in `gm-protocol.md`. Start with repair/upgrade (improve equipment by one tier) rather than creation-from-scratch.
- **Dependencies:** Requires loot system to drop crafting materials, economy system to price materials, and skill system to provide crafting modifiers.
- **Design Decision Required:** YES — when should crafting be implemented?

### Finding 5: Survival Economy Has No Mechanical Backing — ADDRESSED (v4.5.10)

- **Severity:** LOW (for combat balance), HIGH (for game coherence)
- **Resolution:** Added Starving, Dehydrated, Fatigued conditions to conditions.py. Rest gated on food/water/shelter. Survival tracking section added to conditions.md.
- **Area:** Survival Economy (B4)
- **Evidence:** `scarcity.md:129-148` defines food/water requirements and penalties. No condition in `conditions.py` handles starvation/dehydration. No script tracks consumables. No connection between survival needs and rest benefits.
- **Impact:** The survival-horror tone depends on resource scarcity, but the AI-GM must manually track all survival resources with no script support. Inconsistent tracking is likely. The documented rule "can't long rest without food" is nowhere codified.
- **Recommendation:** Add conditions for Starving/Dehydrated to `conditions.py`. Add a `rest_requirements` check that validates food/water before granting rest benefits. This doesn't need a full inventory system — just condition flags.
- **Dependencies:** Requires deciding how granular survival tracking should be.
- **Design Decision Required:** YES — should survival tracking be codified in scripts or remain purely narrative?

### Finding 6: Combat Scripts Don't Enforce Resource Costs

- **Severity:** MODERATE
- **Area:** AI State Tracking (A5, B5)
- **Evidence:** `combat.py` `create_entity_state()` includes `stamina`, `mana`, `composure` fields. `attack_roll()` never checks or decrements these values. No function validates "enough stamina for this technique."
- **Impact:** Resource tracking relies entirely on AI-GM discipline. In long combats with many NPC entities, resource tracking will drift. NPC behavior trees (`behavior.py`) select actions without considering their own stamina/mana pools.
- **Recommendation:** Add a `spend_resource(entity_state, resource, amount)` utility that returns True/False and decrements the pool. Have NPC behavior trees check resource availability before selecting techniques.
- **Design Decision Required:** NO — this is clearly a missing implementation.

### Finding 7: Composure Is Rarely Pressured — ADDRESSED (v4.5.10)

- **Severity:** LOW
- **Resolution:** Added 6 universal composure pressure sources (ally drops, ally dies, outnumbered, prolonged combat, horrific scene, failed death save). COMPOSURE_TRIGGERS dict added to conditions.py. Non-Speaker L5 now reaches Shaken after 2 tough fights.
- **Area:** Resource Economy (A1)
- **Evidence:** Non-social build at L5 has Composure 48. Fear effects deal 2-4 damage (avg 3). 8 fear hits needed to reach Shaken. Most encounters feature 0-1 fear sources, and targets get WIL saves.
- **Impact:** Composure functions primarily as a Speaker offensive resource, not a shared survival resource. Non-Speaker characters rarely interact with their Composure pool. This is acceptable if intentional (Composure is the Speaker's unique domain) but means the "fourth resource pool" doesn't create universal pressure the way HP does.
- **Recommendation:** Consider adding more composure pressure sources: "witnessing ally death" (-5 composure), "combat lasting 6+ rounds" (fatigue: -2 composure/round after round 6), "outnumbered 2:1" (-3 composure/round). This would make Composure relevant to all builds.
- **Design Decision Required:** YES — should Composure be a universal pressure resource or a Speaker-exclusive one?

### Finding 8: Shield Has No Tier Scaling — ADDRESSED (v4.5.10)

- **Severity:** LOW
- **Resolution:** Added shield tier system (Light T1-T5: +1/+1/+2/+2/+3, Heavy T1-T5: +2/+2/+3/+3/+4). Shield tier bonus increases at half the rate of armor (+1 per 2 tiers).
- **Area:** Equipment Scaling (B2)
- **Evidence:** `equipment.md:80-81`: Light Shield +1 DEF, Heavy Shield +2 DEF. No tier system for shields — these are flat bonuses with no upgrade path.
- **Impact:** Shields become relatively less valuable at higher levels. A +2 DEF bonus is 20% of DEF at L1 (DEF 10) but only 10% at L20 (DEF 19). Shield-using builds (Guardian, Warden) don't benefit from equipment progression in their defining item.
- **Recommendation:** Add shield tiers following the armor pattern: T1=base, T2=+1, T3=+2, T4=+3, T5=+4 additional DEF. A heavy shield would go from +2 (T1) to +6 (T5).
- **Design Decision Required:** YES — should shields have tiers?

---

## Design Decisions Required

| # | Decision | Options | Urgency |
|---|----------|---------|---------|
| 1 | **Stamina-Mana parity** | (a) Buff Stamina formula, (b) Nerf Mana formula, (c) Adjust recovery rates, (d) Adjust technique costs | HIGH — affects all martial/caster balance |
| 2 | **Tank invulnerability at T4+** | (a) Flatten armor tier scaling, (b) Add armor penetration to enemies, (c) Accept as feature | MEDIUM — only affects high-level play |
| 3 | **Crafting system** | (a) Build now, (b) Stub out minimal repair/upgrade, (c) Defer | LOW — game functions without it |
| 4 | **Survival tracking** | (a) Codify in scripts, (b) Add conditions only, (c) Keep narrative | MEDIUM — affects tone consistency |
| 5 | **Combat resource enforcement** | (a) Add spend_resource() to combat.py, (b) Document as AI-GM responsibility | MEDIUM — affects AI-GM reliability |
| 6 | **Composure universality** | (a) Add more pressure sources, (b) Keep Speaker-focused | LOW — current design works |
| 7 | **Shield tiers** | (a) Add tier scaling, (b) Keep flat | LOW — minor gap |

---

## Appendix: Source File Index

| File | Role in Audit |
|------|---------------|
| `scripts/character.py:270-276` | Resource pool formulas (HP, Stamina, Mana, Composure) |
| `scripts/character.py:278-281` | DEF formulas (Physical, Mental, Resistance) |
| `scripts/combat.py:18-39` | Stance definitions (AP, RP, ATK, DEF, DMG) |
| `scripts/combat.py:50-124` | Attack resolution (damage calculation, armor subtraction) |
| `scripts/combat.py:336-446` | Entity state normalization (unified schema) |
| `scripts/creature.py:240-254` | Enemy stat formulas (HP, ATK, DEF, DMG, armor) |
| `scripts/conditions.py:10-256` | Standardized conditions (28 conditions, HP/Composure states) |
| `references/equipment.md:48-54` | Weapon tier table (DMG, ATK, requirements) |
| `references/equipment.md:94-100` | Armor tier table (DEF bonus, requirements) |
| `references/conditions.md:88-134` | Composure system (costs, damage, states, recovery) |
| `references/conditions.md:189-203` | Rest & Recovery rules |
| `references/scarcity.md` | Loot economy, currency, survival resources |
| `references/hard-rules.md:109-124` | Resource pacing targets |
| `references/math-assumptions.md:128-161` | Resource pool budgets (design intent) |
| `references/forms-combat-expanded.md` | Technique stamina costs (T1=2-3, T2=4-6, T3=7-8) |
