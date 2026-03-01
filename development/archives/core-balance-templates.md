# Core Balance & Generation Templates

This document establishes the mathematical foundation for all character options and provides generation templates for procedural content.

---

## Combat Math Foundation

### Resolution Baseline
- **System:** 2d6 + modifier vs. DC
- **Average roll:** 7
- **Standard deviation:** ~2.42
- **Target hit rate:** 50-65% for level-appropriate combat

### Hit Probability Table
| Modifier Differential | Roll Needed | Hit Rate |
|----------------------|-------------|----------|
| +5 | 5+ | 83.33% |
| +4 | 6+ | 72.22% |
| +3 | 7+ | 58.33% |
| +2 | 8+ | 41.67% |
| +1 | 9+ | 27.78% |
| +0 | 10+ | 16.67% |
| -1 | 11+ | 8.33% |
| -2 | 12 | 2.78% |

### PC Stat Progression

> **HP formula:** `20 + (MIG × 2) + (FOR × 2) + (Level × 3)`. Table assumes MIG 10 for both columns.

| Level | Attr Points | Primary Attr | Primary Mod | HP (MIG 10, FOR 10) | HP (MIG 10, FOR 16) |
|-------|-------------|--------------|-------------|---------------------|---------------------|
| 1 | +3 (start) | 13 | +1 | 63 | 75 |
| 5 | +6 | 16-17 | +3 | 75 | 87 |
| 10 | +12 | 19-20 | +4-5 | 90 | 102 |
| 15 | +18 | 21-22 | +5-6 | 105 | 117 |
| 20 | +24 | 23-24 | +6-7 | 120 | 132 |
| 25 | +30 | 25-26 | +7-8 | 135 | 147 |
| 30 | +36 | 26-27 | +8 | 150 | 162 |

### Enemy Stat Baseline

> **Source:** `scripts/creature.py` formulas (v4.5.9). Standard threat, no creature/region modifiers.
> ATK = `3 + (level * 2) // 5`, DEF = `10 + (level * 2) // 5`

| Level | HP | DEF | ATK | DMG/Hit | DPR (42% hit) |
|-------|-----|-----|-----|---------|---------------|
| 1 | 26 | 10 | +3 | 4 | 1.7 |
| 3 | 30 | 11 | +4 | 6 | 2.5 |
| 5 | 34 | 12 | +5 | 8 | 3.4 |
| 10 | 44 | 14 | +7 | 13 | 5.5 |
| 15 | 54 | 16 | +9 | 18 | 7.6 |
| 20 | 64 | 18 | +11 | 23 | 9.7 |
| 25 | 74 | 20 | +13 | 28 | 11.8 |
| 30 | 84 | 22 | +15 | 33 | 13.9 |

### Threat Multipliers
| Threat | HP | DEF | ATK | DMG |
|--------|-----|-----|-----|-----|
| Minion | ×0.5 | -2 | -1 | ×0.7 |
| Standard | ×1.0 | +0 | +0 | ×1.0 |
| Elite | ×1.5 | +2 | +2 | ×1.3 |
| Boss | ×3.0 | +3 | +3 | ×1.5 |
| Legendary | ×5.0 | +4 | +4 | ×2.0 |

---

## Power Budget Framework

### Baseline: The Basic Attack
**Cost:** 1 AP, 0 Resources
**Output:** Weapon damage + stat mod

| Weapon Class | Base Damage | +Mod | Expected @ 50% |
|--------------|-------------|------|----------------|
| Light | 1d6 (3.5) | +1-3 | 2.25-3.25 |
| Medium | 1d8 (4.5) | +1-3 | 2.75-3.75 |
| Heavy | 1d10 (5.5) | +1-3 | 3.25-4.25 |

**Design Target:** Special abilities should exceed baseline by 20-50% efficiency when accounting for all costs.

---

## Form Slot Progression

| Level | Form Slots | Cumulative |
|-------|------------|------------|
| 1 | 2 (starting) | 2 |
| 4 | +1 | 3 |
| 8 | +1 | 4 |
| 12 | +1 | 5 |
| 16 | +1 | 6 |
| 20 | +1 | 7 |
| 24 | +1 | 8 |
| 28 | +1 | 9 |

**Starting Forms:**
- Choose from 4 options: 2 determined by Aspect, 2 determined by Archetype
- All subsequent forms must be found (scrolls, manuals, teachers)

---

## Technique Power Budgets

### By Tier

| Tier | Damage Equivalent | Effect Strength | AP | Resource |
|------|-------------------|-----------------|-----|----------|
| 1 | +2-3 or conditional +4-5 | Minor tactical | 1 | 2-3 |
| 2 | +4-6 or multi-target ×2 | Moderate tactical | 1-2 | 3-5 |
| 3 | +6-10 or multi-target ×3 | Strong/build-enhancing | 2-3 | 5-8 |
| 4 | Form-defining | Mastery transformation | 2-3 | 6-10 |

### Variant Modifiers
Each form has 3 variants. Variants modify ALL techniques slightly and provide 1 unique technique per tier.

**Variant Modifier Types:**
| Modifier Type | Effect |
|---------------|--------|
| Aggressive | +1 damage, -1 DEF while using |
| Defensive | +1 DEF, -1 damage while using |
| Precise | +1 to hit, -1 damage |
| Brutal | +2 damage, -1 to hit |
| Quick | -1 AP cost (min 1), -2 damage |
| Heavy | +3 damage, +1 AP cost |
| Flowing | +1m movement per technique, +1 Stamina cost |
| Conserving | -1 resource cost, -1 to hit |

---

## Technique Unlock Conditions

Techniques are NOT unlocked by use count. They must be discovered.

### Unlock Methods

**1. Found Scroll/Manual (Loot)**
- Drop rates tied to enemy tier
- Scrolls are form-specific and tier-specific
- Minion: 0.5% T1, 0% T2+
- Standard: 2% T1, 0.5% T2, 0% T3+
- Elite: 5% T1, 2% T2, 0.5% T3
- Boss: 10% T1, 5% T2, 2% T3, 0.5% T4

**2. Master NPC Teacher**
- Requires finding NPC with technique
- Requires payment/quest/favor
- NPC teaches ONE technique per interaction
- Time: 1 week training per tier

**3. Survival Unlock (Situational)**
- Specific combat conditions trigger unlock
- Examples:
  - "Desperate Strike" - Survive combat at 1 HP
  - "Counter Flow" - Successfully dodge 5 attacks in one combat
  - "Killing Blow" - Land a finishing hit on enemy 10+ levels higher
  - "Stand Alone" - Win combat against 5+ enemies solo
- Each technique has specific unlock condition listed

**4. Witnessed Learning**
- See enemy use technique
- Make INT/WIS check (DC 14 + Tier × 2)
- On success, can attempt to learn (1 week practice)
- On critical success, learn immediately
- Can only attempt once per technique witnessed

### Scroll Generation
```
TECHNIQUE SCROLL DROP

When generating loot:
1. Roll for scroll drop (% based on enemy tier)
2. If scroll drops, determine form:
   - 60%: Form enemy was using
   - 40%: Random form appropriate to creature type
3. Determine tier:
   - Weighted by enemy level vs. technique tier
   - T1: Always possible
   - T2: Enemy level 5+
   - T3: Enemy level 10+
   - T4: Enemy level 20+ AND special conditions
4. If form has variants, scroll specifies variant OR
   is "Universal" (30% chance, works for any variant)
```

---

## Talent Power Budgets

### By Tier
| Tier | Prerequisites | Combat Value | eHP Equiv | DPR Equiv |
|------|---------------|--------------|-----------|-----------|
| 1 | None | Minor | +5-10 | +0.5-1.0 |
| 2 | T1 + Attr 12+ OR Level 5+ | Moderate | +10-20 | +1.0-2.0 |
| 3 | T2 + Attr 16+ OR Level 10+ | Strong | +20-35 | +2.0-4.0 |
| 4 | T3 + Level 15+ | Build-defining | +35-60 | +4.0-8.0 |

### Effect Equivalencies
| Effect | Value |
|--------|-------|
| +1 to hit | ~0.5 DPR |
| +1 damage | ~0.5 DPR (at 50% hit) |
| +1 DEF | ~0.5 enemy DPR reduction |
| +5 HP | ~+5 eHP |
| +1 save | ~+3 eHP (situational) |
| Advantage | ~+3.5 modifier equivalent |
| Resistance | ~+50% eHP vs. type |

---

## Skill Generation Template

Skills are dropped abilities, NOT form techniques. They should feel powerful and exciting.

### Skill Structure
```
SKILL: [NAME]
Rarity: [Common/Uncommon/Rare/Epic/Legendary]
Category: [Combat/Magic/Hybrid/Utility]
Resource: [Stamina/Mana/HP] [Amount]
AP Cost: [1-3]
Range: [Self/Touch/Xm]
Attribute: [Scaling stat]

Base Effect:
[Primary effect description]
[Damage: XdY + [Attr] mod [type]]

Scaling: +[bonus] per rank above Novice

Ranks:
- Novice (default): Base effect
- Apprentice (100 uses): Choose Path A, B, or C
- Expert (300 uses): Path grants 2 techniques
- Master (600 uses): Ultimate technique unlocks
```

### Skill Power Budgets

| Rarity | Base Damage | Rider Value | Total AP | Resource | DPR Efficiency |
|--------|-------------|-------------|----------|----------|----------------|
| Common | 1d6+mod | +2 minor | 1 | 2-3 | Baseline |
| Uncommon | 2d6+mod | +4 moderate | 1-2 | 4-5 | +20-30% |
| Rare | 3d6+mod | +8 (multi/cond) | 2 | 6-8 | +40-60% |
| Epic | 4d6+mod | +12 (strong) | 2-3 | 10-12 | +70-100% |
| Legendary | 5d6+mod | +20 (game-change) | 3 | 15-18 | +100-150% |

### Skill vs. Technique Distinction

| Aspect | Techniques | Skills |
|--------|------------|--------|
| Source | Form mastery | Skill stone drops |
| Cost | AP + Moderate resource | AP + High resource |
| Power | Efficient, tactical | Burst, impactful |
| Frequency | Every turn | 1-3 per combat |
| Feel | "My reliable combo" | "Save for the moment" |
| Variety | Fixed per form/variant | Infinite procedural |

### Skill Generation Framework

```
STEP 1: DETERMINE RARITY
Roll or select based on drop source:
- Standard enemy: 70% Common, 25% Uncommon, 5% Rare
- Elite enemy: 40% Common, 40% Uncommon, 18% Rare, 2% Epic
- Boss: 20% Uncommon, 50% Rare, 25% Epic, 5% Legendary
- Quest reward: Typically Rare-Epic
- Legendary event: Legendary guaranteed

STEP 2: DETERMINE CATEGORY (d8)
1-3: Combat (Stamina-based, physical)
4-6: Magic (Mana-based, elemental/arcane)
7: Hybrid (Both resources)
8: Utility (Non-damage primary)

STEP 3: DETERMINE PRIMARY EFFECT

Combat Effects (d10):
1. Single-target burst (high damage)
2. Multi-target sweep (moderate, 2-3 targets)
3. AOE (all in area)
4. Movement combo (attack + reposition)
5. Condition + damage (debuff)
6. Counter/reaction (defensive offense)
7. Self-buff + attack (enhancement)
8. Execution (bonus vs. wounded)
9. Control (knockback, prone, pull)
10. Sustained (multiple attacks over turns)

Magic Effects (d10):
1. Direct damage (bolt/ray)
2. Area damage (explosion, cone, line)
3. DOT (burning, poison, bleed)
4. Crowd control (slow, root, stun)
5. Buff/shield (protection, enhancement)
6. Summon (temporary ally)
7. Terrain (create cover, hazard)
8. Drain (life steal, mana steal)
9. Transform (polymorph, alter)
10. Utility+ (detection, movement, special)

STEP 4: CALCULATE COSTS
Use Skill Power Budget table based on rarity.

STEP 5: DETERMINE SCALING ATTRIBUTE
- Physical melee: MIG or AGI
- Physical ranged: PRC or AGI
- Elemental magic: INT
- Nature/divine: WIS
- Blood/psionic: WIL
- Defensive: FOR
- Social/command: PRE
- Hybrid: Player choice of 2

STEP 6: GENERATE NAME
[Aspect Influence] + [Effect Core] + [Power Modifier]

Components by Aspect:
- Ore: Stone, Iron, Mountain, Quake, Forge, Adamant
- Tide: Wave, Frost, Deep, Current, Rime, Glacier
- Pyre: Flame, Ember, Ash, Blaze, Phoenix, Inferno
- Gale: Storm, Thunder, Wind, Flash, Tempest, Cyclone
- Radiance: Dawn, Light, Solar, Vital, Beacon, Glory
- Shroud: Shadow, Blood, Grave, Void, Blight, Wither
- Anima: Beast, Spirit, Wild, Fang, Primal, Totem
- Aether: Rift, Phase, Null, Warp, Chrono, Dimension

Effect Cores:
- Strike, Slash, Crush, Pierce (physical)
- Bolt, Blast, Wave, Storm (magic damage)
- Shield, Ward, Barrier, Aegis (defense)
- Step, Rush, Leap, Vault (movement)
- Grasp, Bind, Chain, Lock (control)
- Surge, Pulse, Burst, Nova (area)

Power Modifiers:
- Common: Minor, Lesser, Basic, Simple
- Uncommon: [none - clean name]
- Rare: Greater, True, Keen, Fierce
- Epic: Supreme, Perfect, Masterful, Grand
- Legendary: Ultimate, Transcendent, Absolute, Mythic

STEP 7: GENERATE PATHS (Apprentice rank)
Create 3 specialization paths based on different attributes:
- Path A: Primary attribute emphasis (doubles down)
- Path B: Secondary attribute (adds utility/defense)
- Path C: Tertiary attribute (enables hybrid builds)

STEP 8: GENERATE TECHNIQUES (Expert rank)
Each path provides 2 techniques that enhance the skill:
- One passive modifier
- One active variant/combo

STEP 9: GENERATE MASTERY (Master rank)
Ultimate technique that transforms how skill functions:
- Dramatically reduces cost, OR
- Adds powerful secondary effect, OR
- Allows skill to affect multiple targets, OR
- Grants passive benefit while skill on cooldown
```

### Sample Generated Skill

```
SKILL: THUNDERSTRIKE
Rarity: Rare
Category: Magic
Resource: 8 Mana
AP Cost: 2
Range: 30m
Attribute: INT

Base Effect:
Call lightning from above to strike a target. The bolt then 
arcs to up to 2 additional enemies within 5m of the primary target.
Primary: 3d6 + INT mod lightning damage
Secondary targets: 2d6 lightning damage
All targets wearing metal armor: +2 damage

Scaling: +1d6 primary damage per rank above Novice

Ranks:
- Novice: Base effect
- Apprentice (100 uses): Choose path:
  - Storm's Fury (INT): +50% damage, explosions on crit
  - Tempest Control (WIS): Choose arc targets, can heal allies for 1d6
  - Living Conduit (FOR): Self-centered option, immune to own arcs
- Expert (300 uses): Path techniques unlock
  - Storm's Fury: "Chain Mastery" (arcs to 4 targets), "Critical Storm" (+2 crit range)
  - Tempest Control: "Selective Bolts" (never hit allies), "Storm Shield" (1d6 shield on use)
  - Living Conduit: "Absorb Lightning" (heal from lightning), "Discharge" (melee arc attack)
- Master (600 uses): "Eye of the Storm"
  - Thunderstrike costs 4 Mana. Once per rest, call a Storm (30m radius, 3 rounds):
    all enemies take 2d6 lightning at start of turn, you can cast Thunderstrike 
    as 1 AP while storm active.
```

---

## Procedural Passive Template

At levels 3, 7, 12, 18, 25, players receive 3 procedurally generated passive options.

### Generation Framework

```
PROCEDURAL PASSIVE GENERATION

STEP 1: ANALYZE BUILD PATTERN
Gather data:
- Primary attribute (highest modifier)
- Secondary attribute (second highest)
- Aspect (thematic elements)
- Archetype (role tendencies)
- Forms selected (combat style)
- Skills acquired (power preferences)
- Combat history (frequent actions)
- Survival events (what nearly killed them)

STEP 2: DETERMINE CATEGORY FOR EACH OPTION
Option A: Primary Strength Amplifier
- Enhances what character already does well
- Tied to primary attribute and main form

Option B: Weakness Mitigation / New Synergy
- Addresses a gap in the build
- Often tied to secondary attribute
- May enable new tactical options

Option C: Playstyle Reward
- Based on actual combat behavior
- Rewards patterns the player has demonstrated
- Can be unexpected/emergent

STEP 3: APPLY POWER BUDGET

| Level | Stat Equivalent | Effect Type | Example |
|-------|-----------------|-------------|---------|
| 3 | +3-5 | Conditional +2-4 | "+4 damage when flanking" |
| 7 | +5-8 | Moderate 1/combat | "1/combat, next attack +8 damage" |
| 12 | +8-12 | Significant always-on | "+6 damage vs marked targets" |
| 18 | +12-18 | Major fight-changing | "Below 25% HP: +10 damage, +3 DEF" |
| 25 | +18-25 | Build-altering | "All [type] damage +50%, resist [type]" |

STEP 4: GENERATE NAME AND DESCRIPTION
Name format: [Evocative Adjective] + [Combat Noun]
Examples: Relentless Striker, Patient Guardian, Flowing Counter,
          Savage Instinct, Calculated Precision, Desperate Fury

STEP 5: TIE TO NARRATIVE
Reference specific events from character history:
"Your pattern of [action] has awakened this power."
"Surviving [event] left this mark on your soul."
"Your affinity for [element/style] has deepened."
```

### Sample Procedural Passive Set (Level 7)

**Character:** Gale Skirmisher, AGI 16/PRC 14, Light Weapons + Dual Wield forms, uses hit-and-run tactics, nearly died to AOE attack last session.

```
PROCEDURAL PASSIVE — Level 7

Your combat patterns have crystallized into instinct.

[A] WIND'S ECHO (AGI Focus)
Type: Triggered
When you successfully hit with a light weapon, gain +2m movement 
that doesn't provoke. If you hit twice in one turn, gain +4m instead.
*Your preference for light, quick strikes has merged with your 
Gale aspect, letting you flow like wind between foes.*

[B] DANGER SENSE (PRC Focus)
Type: Passive
+2 DEF against area attacks. When you would take AOE damage, 
reduce it by PRC mod (minimum 1).
*After nearly being incinerated by that Flame Burst, your body 
has learned to read the signs of incoming devastation.*

[C] RELENTLESS PURSUIT (Playstyle Reward)
Type: Triggered
When an enemy you damaged on your last turn moves away from you, 
you may move up to 4m toward them as a free reaction.
*You've developed an instinct for keeping pressure on fleeing 
prey—they cannot escape your blades.*

Select: [A/B/C]
```

---

## Evolution Template

Evolutions occur at levels 10, 20, and 30. Each offers 5 options: 3 core (aspect-gated) + 2 branch (build-derived).

### Evolution Structure

```
EVOLUTION: [NAME]
Type: [Core/Branch]
Gate: [Aspect or Build requirement]
Level: [10/20/30]

Core Passive:
[Always-active benefit, ~2× procedural passive power for level]

Signature Ability:
Name: [Dramatic name]
Cost: [High resource] | Frequency: 1/rest
Effect: [Powerful combat ability, ~Epic skill equivalent]

Talent Tree Unlocked:
[5-6 new talents, Tier 2-4 equivalent]
- [Talent 1]
- [Talent 2]
- [Talent 3]
- [Talent 4]
- [Talent 5]
```

### Evolution Power Budgets

| Level | Passive Value | Signature Power | Talent Tree |
|-------|---------------|-----------------|-------------|
| 10 | +16-24 stat equiv | 4d6+mod + strong rider | 5 talents, T2-3 |
| 20 | +24-36 stat equiv | 6d6+mod + multiple effects | 5 talents, T3-4 |
| 30 | +36-50 stat equiv | 8d6+mod + fight-ending | 6 talents, T3-4 |

### Core Evolution List (By Aspect)

**Each aspect has 3 core evolutions representing different expressions of that element:**

| Aspect | Evolution 1 (Control) | Evolution 2 (Power) | Evolution 3 (Hybrid) |
|--------|----------------------|---------------------|---------------------|
| Ore | Earthshaper | Ironclad | Mountain Sovereign |
| Tide | Tidecaller | Frostborn | Depthwalker |
| Pyre | Flamewarden | Ashbringer | Phoenix Risen |
| Gale | Stormcaller | Tempest | Windwalker |
| Radiance | Dawnbringer | Solaris | Lifegiver |
| Shroud | Shadowmancer | Bloodlord | Deathspeaker |
| Anima | Beastmaster | Wildborn | Spirit Walker |
| Aether | Voidtouched | Chronomancer | Reality Weaver |

### Branch Evolution Generation

```
BRANCH EVOLUTION GENERATION

Branch evolutions emerge from build patterns that don't fit 
core aspect evolutions. Generate 2 branch options per evolution event.

STEP 1: IDENTIFY DIVERGENCE POINTS
Look for:
- Multi-aspect investment (using forms from multiple aspects)
- Archetype/Aspect mismatch builds
- Unusual stat distributions
- Heavy investment in specific form
- Combat role different from archetype suggestion

STEP 2: NAME THE HYBRID
Combine elements: [Primary Element] + [Secondary Pattern]
Examples:
- Gale aspect + Heavy Weapons investment = "Thunderhammer"
- Shroud aspect + Mender archetype = "Lifetaker" (heal by damage)
- Ore aspect + High AGI = "Living Quicksilver"
- Fire aspect + Guardian role = "Crucible"

STEP 3: DESIGN FUSION PASSIVE
The passive should reward BOTH investment patterns.
Example: Thunderhammer
"Heavy weapon attacks deal +4 lightning damage. When you 
knock an enemy prone, they take an additional 2d6 lightning."

STEP 4: DESIGN FUSION SIGNATURE
The signature should combine both elements dramatically.
Example: Thunderhammer
"Storm Giant's Blow — 1/rest, make a heavy weapon attack 
that calls lightning. +6d6 lightning damage, all enemies 
within 5m of target make AGI save or are knocked prone 
and take 3d6 lightning."

STEP 5: DESIGN FUSION TALENT TREE
5 talents that support the hybrid playstyle:
- 2 talents enhancing element 1
- 2 talents enhancing element 2
- 1 talent that specifically requires both
```

### Sample Core Evolution

```
EVOLUTION: STORMCALLER (Gale Core, Level 10)
Type: Core
Gate: Gale Aspect
Level: 10

Core Passive: Storm's Embrace
Lightning damage you deal +25%. You are immune to lightning damage.
Your movement ignores difficult terrain caused by wind or weather.
You can hover 1m above ground at will (no fall damage from short falls).

Signature Ability: Call the Tempest
Cost: 12 Mana | Frequency: 1/rest
Effect: Summon a storm in 20m radius centered on you for 3 rounds.
While storm active:
- Ranged attacks into/through storm have disadvantage
- Enemies starting turn in storm: 2d6 lightning damage
- You may call lightning bolts as 1 AP (30m, 3d6 lightning, single target)
- You can fly within the storm

Talent Tree: Stormcaller
1. STATIC CHARGE (T2): Your movement generates charge. Deal +2 lightning 
   damage for every 4m moved this turn.
2. STORM SENSE (T2): Sense all creatures within 30m during rain/storm. 
   Cannot be surprised by creatures in contact with water or ground.
3. LIGHTNING REFLEXES (T3): Once per round, when hit by an attack, 
   deal 2d6 lightning damage to attacker.
4. RIDE THE LIGHTNING (T3): Once per combat, teleport up to 30m to any 
   creature. Deal 3d6 lightning damage to them on arrival.
5. EYE OF THE STORM (T4): While Call the Tempest is active, you have
   +4 DEF and regenerate 5 HP at start of each turn.
```

### Core Evolution: Ore Aspect

```
EVOLUTION: EARTHSHAPER (Ore Core, Level 10)
Type: Core
Gate: Ore Aspect
Level: 10

Core Passive: Living Terrain
Earth and stone within 10m respond to your will. You gain tremorsense 15m
(detect creatures touching ground). You are immune to forced movement while
standing on earth or stone. You have +3 DEF against ranged attacks when
adjacent to stone (partial cover manifests automatically).

Signature Ability: Reshape the Battlefield
Cost: 11 Mana | Frequency: 1/rest
Effect: Reshape terrain in a 15m radius centered on a point within 30m.
Choose up to 3 of the following effects (each in a distinct 5m area):
- Raise a stone wall (3m tall, 5m wide, 40 HP, DEF 15)
- Open a pit (3m deep, 5m wide; creatures make AGI save DC 14 or fall, 2d6 damage)
- Create difficult terrain (5m area, movement costs doubled)
- Raise a 2m platform (allies on top gain +2 DEF, high ground advantage)
- Flatten all terrain in area (removes cover, walls, obstacles)
Structures persist for 5 rounds or until destroyed.

Talent Tree: Earthshaper
1. STONE GRASP (T2): As 1 AP, cause stone hands to erupt beneath a target
   within 10m. Target makes MIG save DC 13 or is Restrained until end of
   their next turn.
2. TREMOR STEP (T2): When you move on earth or stone, each enemy you pass
   within 3m must make AGI save DC 12 or be knocked Prone.
3. EARTHEN SHIELD (T3): As a reaction, raise a stone slab to block one
   attack against you or an adjacent ally. Reduce incoming damage by 2d6+3.
4. SINKHOLE (T3): Once per combat, target a 5m area within 15m. Ground
   becomes quicksand for 3 rounds. Creatures entering or starting turn
   there are Slowed and take 2d6 bludgeoning damage.
5. TERRAFORM (T4): Your Reshape the Battlefield structures are permanent
   (until destroyed) and you may choose 4 effects instead of 3. Wall HP
   increases to 60.
```

```
EVOLUTION: IRONCLAD (Ore Core, Level 10)
Type: Core
Gate: Ore Aspect
Level: 10

Core Passive: Adamantine Constitution
You gain damage reduction 3 (reduce all incoming damage by 3, minimum 1).
Your maximum HP increases by 15. You are immune to Bleed and Fracture
conditions. When you are hit by a melee attack, the attacker takes 2
bludgeoning damage (iron skin recoil).

Signature Ability: Unyielding Fortress
Cost: 10 Stamina | Frequency: 1/rest
Effect: For 3 rounds, your body becomes living metal.
While active:
- Damage reduction increases to 6
- You are immune to critical hits
- You cannot be knocked Prone, Pushed, or Stunned
- Melee attackers take 2d6 bludgeoning damage on hit
- Your melee attacks deal +4 bludgeoning damage

Talent Tree: Ironclad
1. IRON FIST (T2): Your unarmed attacks deal 1d8+MIG bludgeoning damage
   instead of 1d4. On a critical hit, the target is Dazed for 1 round.
2. METAL RESONANCE (T2): When you take 10+ damage from a single attack,
   gain +2 to your next attack roll as the impact fuels your counterattack.
3. REFLECTIVE PLATING (T3): Once per round, when a ranged attack misses
   you by 3 or more, deflect it to a target within 10m. Make an attack
   roll using the original attack's modifier against the new target.
4. EARTHEN REGENERATION (T3): While standing on earth or stone, regenerate
   3 HP at the start of each of your turns. If below 25% HP, regenerate
   6 HP instead.
5. LIVING BULWARK (T4): While Unyielding Fortress is active, allies within
   3m of you gain damage reduction 3 and cannot be knocked Prone. You may
   intercept one attack per round targeting an adjacent ally, taking the
   damage yourself (after your damage reduction).
```

```
EVOLUTION: MOUNTAIN SOVEREIGN (Ore Core, Level 10)
Type: Core
Gate: Ore Aspect
Level: 10

Core Passive: Seismic Authority
You have +2 to all attack rolls while standing on earth or stone. Enemies
within 5m of you treat the ground as difficult terrain (your presence
destabilizes the earth). You gain +10 maximum HP. When you land a critical
hit, the ground cracks in a 3m radius around the target — all enemies in
that area must make AGI save DC 13 or be knocked Prone.

Signature Ability: Sovereign's Quake
Cost: 8 Stamina + 6 Mana | Frequency: 1/rest
Effect: Slam the ground, sending a seismic wave in a 15m radius.
All enemies in radius:
- Take 4d6+MIG bludgeoning damage (AGI save DC 15 for half)
- Are knocked Prone (no save)
- Lose 1 AP on their next turn (the ground continues to tremble)
You then claim the area: for 3 rounds, you have tremorsense 30m,
+3 DEF, and can use 1 AP to cause a 3m area within 15m to erupt
(2d6 bludgeoning, AGI save DC 13 to avoid Prone).

Talent Tree: Mountain Sovereign
1. FAULT LINE (T2): As 2 AP, draw a 10m line on the ground. Enemies
   crossing the line take 2d6 bludgeoning damage and must make AGI save
   DC 13 or be knocked Prone. Line persists for 2 rounds.
2. STONE MANTLE (T2): At the start of combat, gain temporary HP equal to
   your level + FOR mod. When this temporary HP is depleted, it explodes
   in a 3m radius for 1d6 bludgeoning damage.
3. TECTONIC COMMAND (T3): Once per combat, shift a creature standing on
   earth up to 5m in any direction along the ground (no save). This
   movement provokes opportunity attacks.
4. QUAKE STEP (T3): When you move at least 6m on your turn, your next
   melee attack this turn deals +2d6 bludgeoning damage and targets
   all enemies within 2m of the primary target.
5. SOVEREIGN'S DOMAIN (T4): While Sovereign's Quake area is active,
   enemies in the area have -2 to all attack rolls and -2 DEF. You
   can spend 1 AP to raise or collapse terrain within the domain
   (create or destroy cover, walls, or pits up to 3m).
```

### Core Evolution: Tide Aspect

```
EVOLUTION: TIDECALLER (Tide Core, Level 10)
Type: Core
Gate: Tide Aspect
Level: 10

Core Passive: Current's Will
Water within 15m obeys your command. You can breathe underwater and
swim at your full movement speed. You are immune to Slowed when caused
by water or ice effects. Enemies within 10m that are wet or standing
in water have -2 DEF against your attacks.

Signature Ability: Raging Torrent
Cost: 12 Mana | Frequency: 1/rest
Effect: Conjure a surging flood that fills a 20m radius area for 3 rounds.
While torrent active:
- The area is difficult terrain for enemies (not allies)
- Enemies starting their turn in the water: 2d6 cold damage
- You can command the current as 1 AP: push all enemies in a 10m line
  up to 5m in a direction of your choice (MIG save DC 14 negates)
- You may freeze a 5m area as 1 AP (becomes ice: Prone check AGI DC 13
  to cross, lasts 2 rounds)

Talent Tree: Tidecaller
1. UNDERTOW (T2): When you push an enemy with a water effect, they take
   1d6 cold damage and must make FOR save DC 12 or be Slowed until end
   of their next turn.
2. WATER LENS (T2): You can see perfectly through water and fog. Gain
   +3 to perception checks in rain, mist, or near bodies of water.
   Enemies cannot use fog or mist for concealment against you.
3. RIPTIDE (T3): Once per combat, when an enemy moves within 10m of
   you, pull them up to 5m toward you as a reaction. If they end
   adjacent to you, make a free melee attack against them.
4. FROZEN CAGE (T3): As 2 AP, 6 Mana, encase a target within 10m in
   ice. Target makes FOR save DC 14: on failure, Restrained for 2 rounds
   (can repeat save at end of each turn). On success, Slowed for 1 round.
5. DELUGE (T4): While Raging Torrent is active, you may spend 2 AP to
   create a tidal wave: 10m wide, 15m long. All creatures in path take
   3d6 cold damage and are pushed 5m (MIG save DC 15 for half damage,
   no push).
```

```
EVOLUTION: FROSTBORN (Tide Core, Level 10)
Type: Core
Gate: Tide Aspect
Level: 10

Core Passive: Heart of Winter
You are immune to cold damage and the Frozen condition. Your melee attacks
deal +3 cold damage. When you are hit by a melee attack, the attacker's
weapon frosts over: they deal -2 damage on their next attack. You generate
an aura of cold — enemies ending their turn within 3m of you take 2 cold
damage.

Signature Ability: Absolute Zero
Cost: 11 Mana | Frequency: 1/rest
Effect: Encase yourself in living ice armor for 3 rounds.
While active:
- Gain 25 temporary HP (ice armor)
- Your DEF increases by +3
- Your melee attacks deal +2d6 cold damage and apply Chilled
  (Slowed for 1 round, stacks to Frozen on second application)
- When the ice armor breaks (temp HP depleted), it explodes:
  all enemies within 5m take 3d6 cold damage and are Chilled

Talent Tree: Frostborn
1. FLASH FREEZE (T2): When you deal cold damage to a Slowed enemy,
   they must make FOR save DC 13 or become Frozen (Stunned, +4 damage
   from next attack shatters the ice). Frozen lasts 1 round.
2. ICE WALK (T2): You can walk on water by freezing it beneath your
   feet. You ignore difficult terrain caused by ice or snow. Leave a
   trail of frost: enemies crossing your path make AGI save DC 11 or
   fall Prone.
3. PERMAFROST (T3): Your cold aura radius increases to 5m and damage
   increases to 4. Enemies that start their turn in the aura are
   Slowed until end of their turn.
4. GLACIAL STRIKES (T3): Once per turn, when you hit with a melee
   attack, conjure an ice spike that strikes a second enemy within 5m
   for 2d6 cold damage.
5. WINTER'S HEART (T4): While Absolute Zero is active, you regenerate
   5 temporary HP at the start of each turn (rebuilding ice armor, up
   to original 25 cap). When you would be reduced to 0 HP, the armor
   shatters and you instead remain at 1 HP (once per rest).
```

```
EVOLUTION: DEPTHWALKER (Tide Core, Level 10)
Type: Core
Gate: Tide Aspect
Level: 10

Core Passive: Abyssal Pressure
You exude crushing pressure. Enemies within 5m of you have -1 to all
attack rolls (the weight of the deep). You can breathe underwater, are
immune to pressure-based damage, and have darkvision 20m. Your attacks
ignore 2 points of the target's damage reduction. You gain +10 maximum HP.

Signature Ability: Crush Depth
Cost: 8 Stamina + 5 Mana | Frequency: 1/rest
Effect: Intensify gravitational pressure in a 10m radius around you for
3 rounds.
While active:
- All enemies in radius have their movement halved
- Enemies starting turn in radius: 2d6 bludgeoning damage (FOR save
  DC 15 for half) and cannot jump or fly
- You can target one creature per round as 1 AP: apply Crushing Pressure
  (3d6 bludgeoning, FOR save DC 15 or Prone and Slowed for 1 round)
- You gain +2 to all melee attack rolls within the radius

Talent Tree: Depthwalker
1. PRESSURE WAVE (T2): As 1 AP, release a concussive pulse in a 5m cone.
   Enemies in the cone take 1d6+MIG bludgeoning and are pushed 3m.
   Creatures smaller than you are also knocked Prone.
2. DEEP ADAPTATION (T2): You have resistance to bludgeoning and cold
   damage (take half). Gain +2 to saves against Restrained and Grappled
   conditions.
3. CRUSHING GRIP (T3): Your grapple attacks deal 2d6 bludgeoning damage
   per round. Grappled enemies cannot use reactions. Your grapple checks
   gain +3.
4. ABYSSAL SURGE (T3): Once per combat, as 2 AP, launch yourself up to
   10m toward a target. On arrival, deal 3d6 bludgeoning damage and the
   target must make MIG save DC 14 or be Stunned for 1 round.
5. EVENT HORIZON (T4): While Crush Depth is active, enemies that attempt
   to leave the radius must make MIG save DC 15 or be pulled back to
   their starting position. Flying enemies in the radius are forced to
   the ground. Your Crushing Pressure targeting ability costs 0 AP
   (once per round).
```

### Core Evolution: Pyre Aspect

```
EVOLUTION: FLAMEWARDEN (Pyre Core, Level 10)
Type: Core
Gate: Pyre Aspect
Level: 10

Core Passive: Pyroclastic Domain
You are immune to fire damage and the Burning condition. Fire you create
persists 1 round longer than normal. You can sense heat signatures within
15m (detecting hidden creatures by body heat, +3 to perception vs. hidden
enemies). Allied creatures within 5m of your fire effects take no damage
from them.

Signature Ability: Infernal Sanctum
Cost: 12 Mana | Frequency: 1/rest
Effect: Create a zone of controlled fire in a 15m radius for 4 rounds.
You control all fire within the zone:
- Place up to 4 fire walls (3m long, 2m tall each) anywhere in the zone;
  passing through a wall deals 3d6 fire damage
- Designate up to 3 safe corridors (allies move through fire unharmed)
- Enemies starting turn in the zone: 1d6 fire damage (ambient heat)
- As 1 AP, detonate any fire wall: 5m radius, 2d6 fire damage, wall
  is consumed
- As 1 AP, create a new fire wall to replace a detonated one (max 4 total)

Talent Tree: Flamewarden
1. EMBER WARD (T2): When an enemy enters a space adjacent to one of your
   fire effects, they take 1d6 fire damage. This triggers only once per
   enemy per round.
2. HEAT MIRAGE (T2): While within 5m of your own fire effects, you have
   partial concealment (+2 DEF against ranged attacks). The shimmering
   heat distorts your silhouette.
3. CONTROLLED BURN (T3): You can shape your fire abilities to exclude up
   to 3 squares from any area effect. Your fire effects deal +2 damage
   to enemies that are already Burning.
4. FIREBREAK (T3): As a reaction when an ally within 10m would take
   damage, create a wall of protective fire between them and the attacker.
   Reduce the incoming damage by 2d6+INT mod.
5. MAGMA VEINS (T4): While Infernal Sanctum is active, the ground within
   the zone cracks with magma. Enemies that fall Prone in the zone take
   2d6 additional fire damage. Your fire walls gain +1d6 damage (4d6
   total to pass through). You may maintain the zone for 2 additional
   rounds (6 rounds total).
```

```
EVOLUTION: ASHBRINGER (Pyre Core, Level 10)
Type: Core
Gate: Pyre Aspect
Level: 10

Core Passive: Scorched Fury
Your fire damage rolls gain +3. When you reduce an enemy to 0 HP with
fire damage, an explosion erupts from their body: all enemies within 3m
take 1d6 fire damage. You are immune to fire damage. Your attacks ignore
fire resistance (but not immunity).

Signature Ability: Cataclysm
Cost: 14 Mana | Frequency: 1/rest
Effect: Channel for 1 round, then unleash devastation.
On the following round, choose one:
- METEOR: 5m radius, 30m range. 4d6+INT fire damage. All targets make
  AGI save DC 15: fail = full damage + Burning (1d6/round, 3 rounds);
  success = half damage, no Burning. Area becomes scorched earth
  (difficult terrain, 1d6 fire to enter) for 3 rounds.
- FIRESTORM: 10m radius centered on you. 3d6+INT fire damage to all
  enemies in radius. No save. All enemies are Burning (1d6/round,
  2 rounds). You gain +2 to all attack rolls for 2 rounds from the
  inferno's fury.

Talent Tree: Ashbringer
1. IGNITION (T2): Your first fire attack each combat that hits
   automatically applies Burning (1d6/round, 2 rounds) with no save.
   Subsequent fire attacks apply Burning on a critical hit.
2. FUEL THE FLAMES (T2): When you deal fire damage to a Burning
   target, the Burning duration extends by 1 round and its damage
   increases by +1 (max +3).
3. PYROCLASM (T3): Once per combat, when you deal fire damage to 3 or
   more enemies in a single action, all of them must make FOR save DC 14
   or be Dazed for 1 round (disadvantage on attacks).
4. IMMOLATION AURA (T3): As 1 AP, activate for 3 rounds. You radiate
   intense heat: enemies within 3m take 2d6 fire damage at the start
   of their turn. Melee attackers take 1d6 fire damage when they hit you.
5. FROM THE ASHES (T4): When Cataclysm's scorched earth is active,
   you can draw power from it. While standing on scorched earth: your
   fire attacks deal +2d6 damage, your Burning effects cannot be
   removed by normal means, and you regenerate 3 HP at the start of
   each turn.
```

```
EVOLUTION: PHOENIX RISEN (Pyre Core, Level 10)
Type: Core
Gate: Pyre Aspect
Level: 10

Core Passive: Flame Eternal
You are immune to fire damage. You regenerate 2 HP at the start of each
of your turns. When you fall below 25% maximum HP, this regeneration
increases to 5 HP per turn and your fire damage increases by +4. You
are immune to the Dying condition caused by fire or heat effects.

Signature Ability: Rebirth in Flames
Cost: 15 Mana | Frequency: 1/rest
Effect: Can be activated in two ways:
- ACTIVE: Erupt in a pillar of flame. All enemies within 5m take
  4d6+INT fire damage (AGI save DC 15 for half). You are healed for
  HP equal to half the total damage dealt. Gain Blazing Form for
  2 rounds (fly 10m, fire immunity, melee attacks deal +2d6 fire,
  you shed light and Burning to all who touch you).
- REACTIVE (on reaching 0 HP): Instead of falling, explode in flame.
  All enemies within 5m take 3d6 fire damage (no save). You are
  resurrected at 25% maximum HP with Blazing Form for 1 round.
  You are Exhausted after Blazing Form ends (-2 all rolls for
  remainder of combat).

Talent Tree: Phoenix Risen
1. CAUTERIZE (T2): As 1 AP, touch a creature and spend 3 Mana. Heal
   them for 2d6 HP and remove one Bleed or Poison condition. The target
   takes 1d6 fire damage (which you can negate if targeting yourself).
2. FUNERAL PYRE (T2): When an ally within 10m is reduced to 0 HP,
   flames erupt from their position: all enemies within 3m take 2d6
   fire damage. The ally is stabilized at 1 HP (once per rest per ally).
3. UNDYING EMBER (T3): The first time each combat you would be reduced
   to 0 HP by non-fire damage, instead remain at 1 HP and gain +3 DEF
   for 1 round. This does not consume your Reactive Rebirth.
4. PHOENIX WINGS (T3): While in Blazing Form, your flight speed
   increases to 15m. When you fly over enemies, they take 1d6 fire
   damage (once per enemy per round). You can carry one willing ally
   while flying.
5. ETERNAL FLAME (T4): Your passive regeneration increases to 4 HP
   per turn (8 HP below 25%). When you use Rebirth in Flames (Active),
   Blazing Form lasts 3 rounds instead of 2 and you gain temporary HP
   equal to your level. Reactive Rebirth restores you to 50% HP instead
   of 25%.
```

### Core Evolution: Gale Aspect (Continued)

```
EVOLUTION: TEMPEST (Gale Core, Level 10)
Type: Core
Gate: Gale Aspect
Level: 10

Core Passive: Fury of Wind
Your wind and lightning damage deals +3. Your ranged attacks ignore
penalties from wind, weather, and partial cover (the wind bends your
projectiles). You are immune to forced movement from wind effects.
When you deal damage to a target, they are pushed 2m in a direction
you choose (no save).

Signature Ability: Annihilating Gale
Cost: 13 Mana | Frequency: 1/rest
Effect: Unleash a devastating windstorm. Choose one mode:
- CUTTING GALE: 15m cone. 4d6+INT slashing damage from razor wind.
  All targets make AGI save DC 15: fail = full damage + Bleeding
  (1d6/round, 2 rounds); success = half damage. All loose objects
  in the cone are destroyed or scattered.
- VACUUM CRUSH: 10m radius centered on a point within 20m. All air
  is ripped away. 3d6+INT bludgeoning damage (FOR save DC 15 for half).
  All targets are pulled 5m toward center. Creatures that end at center
  take +2d6 bludgeoning and are Stunned for 1 round (concentration
  shatters). Silence fills the area for 1 round (no verbal abilities).

Talent Tree: Tempest
1. WIND BLADE (T2): As 1 AP, launch a blade of compressed air. 20m
   range, 2d6 slashing damage, target is pushed 3m. If the target
   collides with a wall or creature, both take 1d6 bludgeoning.
2. GALE FORCE (T2): Your push distance from Fury of Wind increases to
   4m. When you push an enemy into another enemy, both take 1d6
   bludgeoning damage and must make AGI save DC 12 or fall Prone.
3. SHEARING WINDS (T3): Your area attacks create lingering wind zones
   (5m radius, 2 rounds). Enemies in the zone have disadvantage on
   ranged attacks and -2 DEF. Projectiles fired through the zone are
   deflected (50% miss chance against targets beyond the zone).
4. TORNADO (T3): Once per combat, as 2 AP, 8 Mana, create a tornado
   at a point within 15m. 3m radius, lasts 2 rounds. Creatures entering
   or starting turn: 2d6 bludgeoning, lifted 3m (AGI save DC 14 negates
   lift). You can move the tornado 5m as a free action each turn.
5. STORM'S EXECUTIONER (T4): When you use Annihilating Gale, you may
   use BOTH modes simultaneously (different targets/areas). Additionally,
   enemies reduced to 0 HP by your wind damage explode outward: all
   enemies within 3m take 2d6 slashing damage.
```

```
EVOLUTION: WINDWALKER (Gale Core, Level 10)
Type: Core
Gate: Gale Aspect
Level: 10

Core Passive: One with the Wind
Your base movement speed increases by 4m. You can Dash as a free action
once per round (move your speed again, costs 0 AP). Opportunity attacks
against you have disadvantage. You take no fall damage. You gain +2 DEF
while you moved at least 6m on your current or previous turn.

Signature Ability: Zephyr Form
Cost: 10 Mana | Frequency: 1/rest
Effect: Become semi-incorporeal wind for 3 rounds.
While in Zephyr Form:
- You can move through enemies and solid objects thinner than 1m
  (you reform on the other side)
- You gain +4 DEF and resistance to all physical damage (half damage)
- Your movement speed doubles
- Each enemy you pass through takes 2d6 slashing damage (once per
  enemy per round) from the cutting wind of your passage
- You can fly at your full movement speed

Talent Tree: Windwalker
1. TAILWIND (T2): Allies within 10m of you gain +2m movement speed.
   Once per round, when an ally moves adjacent to you, they can move
   an additional 3m as a free action (the wind carries them).
2. BLUR (T2): While you moved at least 8m on your previous turn, you
   have partial concealment (20% miss chance against you from ranged
   attacks). Enemies attacking you in melee have -1 to hit.
3. SLIPSTREAM (T3): When you take the Dash free action, choose one
   enemy you pass within 3m of. Make a free melee attack against them
   at +2 to hit. This attack deals weapon damage + AGI mod slashing.
4. AIR STEP (T3): You can walk on air as if it were solid ground,
   ascending or descending at any angle. While airborne, your ranged
   attacks deal +2 damage (diving strikes). You can hover indefinitely.
5. WIND AVATAR (T4): While Zephyr Form is active, you are fully
   incorporeal — immune to physical damage, but can still be hit by
   magic and elemental attacks. Your pass-through damage increases to
   3d6. Once during Zephyr Form, you may reform inside an enemy's
   space: they take 4d6 slashing damage and are Stunned for 1 round
   (no save), and you appear in an adjacent space.
```

### Sample Branch Evolution

```
EVOLUTION: BLADESTORM (Gale + Light Weapons Heavy Investment)
Type: Branch
Gate: Gale Aspect + Light Weapons Form Tier 3+
Level: 10

Core Passive: Electrified Edge
Your light weapon attacks deal +3 lightning damage.
When you hit the same enemy twice in one turn, they are Shocked 
(disadvantage on their next attack, -2 DEF until end of your next turn).

Signature Ability: Thousand Volt Slash
Cost: 8 Stamina + 6 Mana | Frequency: 1/rest
Effect: Make AGI mod attacks against enemies in melee range (minimum 3).
Each attack deals weapon damage + 2d6 lightning.
Enemies hit twice or more are Stunned until end of their next turn.
You may move 2m between each attack without provoking.

Talent Tree: Bladestorm
1. CHARGED BLADE (T2): First attack each combat with light weapon 
   deals +3d6 lightning damage.
2. SPARK STEP (T2): When you use a light weapon technique that allows 
   movement, deal 1d6 lightning to each enemy you pass.
3. LIVING CURRENT (T3): Immune to lightning. When you would take lightning 
   damage, instead gain that much temporary HP.
4. BLADE CONDUCTOR (T3): Your light weapons count as having Reach 
   (attack from 3m). The "reach" is visible lightning arcs.
5. STORM OF STEEL (T4): When you score a critical hit with a light weapon, 
   make a free additional attack against a different enemy within 5m.
```

---

## Awakened NPC Template

For generating Awakened NPCs (human/humanoid enemies with PC-like builds).

### NPC Tier System

| Tier | Description | Build Complexity |
|------|-------------|------------------|
| Grunt | Basic soldier/thug | Stat block only |
| Veteran | Experienced fighter | Stats + 1-2 signature moves |
| Awakened | Player-equivalent | Full aspect/archetype build |
| Champion | Elite Awakened | Full build + evolution |
| Legend | Faction leader tier | Full build + multiple evolutions |

### Awakened NPC Generation

```
AWAKENED NPC: [NAME]
Level: [X]
Tier: [Awakened/Champion/Legend]

Aspect: [Ore/Tide/Pyre/Gale/Radiance/Shroud/Anima/Aether]
Archetype: [Striker/Guardian/Hunter/Skirmisher/Mender/Warden/Analyst/Speaker]
Variant: [Variant name from aspect × archetype]

ATTRIBUTES (Total = 60 + Level):
MIG [X] (+mod) | AGI [X] (+mod) | FOR [X] (+mod) | PRC [X] (+mod)
INT [X] (+mod) | WIS [X] (+mod) | WIL [X] (+mod) | PRE [X] (+mod)

DERIVED STATS:
HP: [20 + (MIG × 2) + (FOR × 2) + (Level × 3)]
Physical DEF: [10 + AGI mod + armor]
Mental DEF: [10 + WIL mod]
Stamina: [10 + (FOR × 2) + AGI + Level]
Mana: [10 + (INT × 2) + WIL + Level]
Composure: [10 + (PRE × 2) + WIL + Level]
Movement: [6m base + AGI mod]
AP: [3 base, modified by stance]

STANCE: [Balanced/Aggressive/Defensive/Mobile/Focused]

EQUIPMENT:
- Weapon: [Type, damage, properties]
- Armor: [Type, DEF bonus, penalties]
- Shield: [If any]
- Special: [Notable items]

FORMS (Slots = 2 + Level/4):
1. [Form Name] - Variant: [X]
   Techniques Known: [List T1-T3 as appropriate for level]
2. [Additional forms...]

SKILLS ([Level/5] skills, minimum 1):
1. [Skill Name] (Rarity) - Rank: [Novice/Apprentice/Expert/Master]
   Effect: [Brief description]
2. [Additional skills...]

TALENTS ([Level - 1] talents):
- [Talent 1]: [Effect summary]
- [Talent 2]: [Effect summary]
- [Additional talents...]

PASSIVES (from breakpoints and procedurals):
- [Attribute breakpoint effects]
- [Procedural passives if level 3+]

EVOLUTION (if Champion/Legend, Level 10+):
[Evolution Name]: [Brief passive and signature description]

TACTICS:
[2-3 sentences on how this NPC fights]

THREAT ASSESSMENT:
Challenge Rating: [Level ± modifier based on gear/talents]
Recommended Party: [X players of level Y]
```

### NPC Attribute Distribution Templates

**By Role:**

| Role | Primary | Secondary | Tertiary | Dump |
|------|---------|-----------|----------|------|
| Melee DPS | MIG/AGI | FOR | PRC | INT/PRE |
| Ranged DPS | PRC/AGI | INT | WIS | MIG |
| Tank | FOR | MIG/WIL | PRE | AGI |
| Caster (Damage) | INT | WIS | WIL | MIG |
| Caster (Support) | WIS | INT/PRE | WIL | MIG |
| Controller | WIL/INT | WIS | PRE | FOR |
| Face/Leader | PRE | WIS/WIL | INT | MIG |

**Point Distribution (Level 10 example, 70 total points):**
- Primary: 18-20 (+4 to +5)
- Secondary: 14-16 (+2 to +3)
- Tertiary: 12 (+1)
- Others: 10 (+0)
- Dump: 8-10 (-1 to +0)

### Sample Awakened NPC

```
AWAKENED NPC: RAZOR VANCE
Level: 8
Tier: Awakened

Aspect: Shroud
Archetype: Skirmisher
Variant: Nightblade

ATTRIBUTES (Total = 68):
MIG 10 (+0) | AGI 18 (+4) | FOR 12 (+1) | PRC 14 (+2)
INT 10 (+0) | WIS 12 (+1) | WIL 14 (+2) | PRE 10 (+0)

DERIVED STATS:
HP: 20 + (10×2) + (12×2) + (8×3) = 88
Physical DEF: 10 + 4 + 3 (leather) = 17
Mental DEF: 10 + 2 = 12
Stamina: 10 + (12×2) + 18 + 8 = 60
Mana: 10 + (10×2) + 14 + 8 = 52
Composure: 10 + (10×2) + 14 + 8 = 52
Movement: 6 + 4 = 10m
AP: 3

STANCE: Mobile (+4m move, +1 DEF, free disengage)

EQUIPMENT:
- Weapon: Paired Daggers (1d6, light, finesse) ×2
- Armor: Shadow Leather (+3 DEF, +2 Stealth)
- Special: Smoke Bombs (×3), Poison Vials (×2)

FORMS (4 slots):
1. Light Weapons (Shiv Variant: +1 damage vs. surprised, bleed on crit)
   - Quick Strike, Opportunistic Stab, Slip Away
   - Flurry, Hamstring
2. Dual Wield (Assassin Variant: +2 damage from stealth, silent kills)
   - Twin Strike, Defensive Whirl
   - Cross Slash
3. Stealth (Shadow Variant: Hide in dim light, see in darkness)
   - Hide, Move Silently
   - Vanish

SKILLS (1):
1. Shadow Step (Rare) - Rank: Apprentice
   2 AP, 5 Mana: Teleport up to 10m to shadow. Next attack from stealth +50% damage.
   Path: Shadow's Embrace (+2 DEF for 1 round after teleport)

TALENTS (7):
- Hit and Run: Move 2m after hitting without provoking
- Flanking Expert: +4 damage when flanking
- Nimble: +2 DEF vs opportunity attacks, +1m speed
- Dual Striker: Off-hand deals full damage
- Blood Scent (Shroud): +2 damage vs wounded, sense wounded 30m
- Death's Touch (Shroud): +2 necrotic damage, +2 Intimidation
- Pain Tolerance (Shroud): Below 50% HP, +1 all rolls

PASSIVES:
- AGI +4: Uncanny Dodge (reduce one attack damage by AGI mod, 1/round)
- PRC +2: Expanded crit range (crits on 11-12)
- Level 7 Procedural: "Ghost Step" - 1/combat, after hitting, move 4m 
  without provoking and become Hidden

TACTICS:
Vance opens from stealth with Shadow Step + Cross Slash for massive 
burst damage. Uses Mobile stance to dart in and out, applying bleeds 
and retreating. If cornered, uses smoke bomb to re-enter stealth.
Targets casters and wounded enemies first.

THREAT ASSESSMENT:
Challenge Rating: 9 (gear and talents increase effective level)
Recommended Party: 4 players of level 6-7, or 3 of level 8
```

---

## Quick Reference: All Budgets

### Damage Per Tier
| Source | Tier 1 | Tier 2 | Tier 3 | Tier 4 |
|--------|--------|--------|--------|--------|
| Technique | +2-3 | +4-6 | +6-10 | Transform |
| Talent | +0.5-1 DPR | +1-2 DPR | +2-4 DPR | +4-8 DPR |
| Skill (by rarity) | 1d6+ (C) | 2d6+ (U) | 3d6+ (R) | 4-5d6+ (E/L) |
| Procedural Passive | +3-5 | +5-8 | +8-12 | +18-25 |
| Evolution Passive | — | — | +16-24 | +24-50 |

### Resource Costs
| Power Level | Stamina | Mana | HP (Blood) |
|-------------|---------|------|------------|
| Minor | 1-2 | 1-2 | 2-3 |
| Moderate | 3-4 | 3-5 | 5-8 |
| Strong | 5-7 | 6-8 | 10-15 |
| Major | 8-10 | 10-12 | 15-20 |
| Extreme | 12+ | 15+ | 25+ |

### AP Economy
| Action | AP Cost |
|--------|---------|
| Basic Attack | 1 |
| Most T1 Techniques | 1 |
| Most T2 Techniques | 1-2 |
| Most T3 Techniques | 2-3 |
| T4 Techniques | 2-3 |
| Common Skill | 1 |
| Uncommon-Rare Skill | 2 |
| Epic-Legendary Skill | 2-3 |
| Movement (base) | 0 (part of turn) |
| Stance Change | 0 (start of turn) |
| Quick Action | 0 |
| Reaction | 0 (limited to 1/round) |
