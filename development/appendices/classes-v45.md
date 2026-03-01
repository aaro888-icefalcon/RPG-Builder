# Classes

## The 64 Classes

```
              STRIKER    GUARDIAN   HUNTER     SKIRMISHER MENDER     WARDEN     ANALYST    SPEAKER
  ORE         Warlord    Knight     Arbalist   Saboteur   Apothecary Sentinel   Artificer  Marshal
  TIDE        Marauder   Bulwark    Deadeye    Corsair    Wellspring Maelstrom  Diviner    Siren
  PYRE        Berserker  Immolator  Bombardier Hellion    Firekeeper Pyromancer Alchemist  Firebrand
  GALE        Tempest    Vanguard   Windrunner Dervish    Monk       Stormcaller Tactician Herald
  RADIANCE    Paladin    Templar    Inquisitor Crusader   Cleric     Beacon     Oracle     Prophet
  SHROUD      Reaper     Revenant   Wraith     Assassin   Witch      Hexer      Necromancer Harbinger
  ANIMA       Savage     Beastmaster Ranger    Prowler    Druid      Shaman     Sage       Chieftain
  AETHER      Battlemage Aegis      Warlock    Magus      Mystic     Spellbreaker Arcanist Enchanter
```

*Stat bonuses are defined in the Python scripts and applied automatically via `emergence_cli.py character`. For reference: Aspects give +2/+1 to their thematic stats, Archetypes give +2/+1 to their role stats. Bonuses stack freely (no hard caps).*

---

## Form Pool System

**Archetype Base Pools:**

| Archetype | Pool (5 forms) |
|-----------|----------------|
| Striker | Heavy Crush, Medium Blade, Unarmed, Shield, Athletics |
| Guardian | Shield, Defensive Arts, Heavy Crush, Warding, Medium Blade |
| Hunter | Ranged, Light Blade, Stealth, Traps, Perception |
| Skirmisher | Dual Wield, Light Blade, Finesse Blade, Acrobatics, Thrown |
| Mender | Healing, Medicine, Light, Warding, Medium Blade |
| Warden | Control*, Warding, Medium Blade, Perception, Survival |
| Analyst | Knowledge*, Crafting, Perception, Traps, Light Blade |
| Speaker | Diplomacy, Deception, Performance, Intimidation, Light Blade |

*Control and Knowledge vary by Aspect (see modifiers).

**Aspect Modifiers (swap 1-2 forms):**

| Aspect | Adds | Replaces |
|--------|------|----------|
| Ore | Heavy Armor, Smithing | Lightest combat option |
| Tide | Water Magic, Navigation | Utility slot |
| Pyre | Fire Magic, Demolition | Control/Knowledge magic |
| Gale | Wind Magic, Acrobatics | Heaviest option |
| Radiance | Light Magic, Purification | Deception/Stealth |
| Shroud | Shadow Magic, Stealth | Light/Healing magic |
| Anima | Nature Magic, Beast Bond | Crafting/Knowledge |
| Aether | Arcane Magic, Ritual | Add to any pool |

**Resolution:** Archetype pool → apply Aspect modifier → 5-6 forms. Player chooses 1.

---

## Awakening Passive Categories

Awakening passives fall into two categories based on activation reliability:

### Consistent Passives (Always Active)

**Design Target:** +2-4 effective stat equivalent at L1

These passives work without requiring specific conditions:
- Permanent stat bonuses (DR, initiative, movement)
- Condition immunities (surprise, fear)
- Resource modifications (increased recovery, larger pools)

**Examples:**
- Knight's *Iron Resolve*: DR on first hit each round (combat always has "first hit")
- Oracle's *Foresight*: Cannot be surprised, +2 Initiative (always active)

### Conditional Passives (Requires Trigger)

**Design Target:** +4-8 effective stat equivalent when active

These passives require specific conditions to activate:
- Kill triggers (must land killing blow)
- Stealth triggers (must be hidden)
- Wound triggers (must be below threshold)
- Position triggers (must be flanking, elevated, etc.)

**Examples:**
- Reaper's *Death's Harvest*: Heal on killing blow (must kill to trigger)
- Assassin's *Death's Shadow*: +50% damage from stealth (must be hidden)

### Scaling Pattern (All Awakenings)

| Level | Effect Power | Typical Upgrade |
|-------|--------------|-----------------|
| 1 | Base effect | — |
| 10 | 2× base OR new application | Effect doubles or gains new use case |
| 20 | 4× base OR significant capability | Major power increase |
| 30 | Build-defining ultimate | Transforms playstyle |

**Example (Knight - Consistent):**
- L1: DR = FOR mod on first hit each round
- L10: DR on first TWO hits each round
- L20: Redirect provokes opportunity attack on original attacker
- L30: DR on ALL hits, redirect is free action

**Example (Reaper - Conditional):**
- L1: Heal WIL mod on killing blow
- L10: Heal + temp HP, can mark target for +4 damage
- L20: Killing marked target heals all allies in 10m
- L30: Extra attack on kill, mark damage increases to +50%

---

## Awakening Scaling Patterns

| Pattern | How It Scales L1 → L30 |
|---------|------------------------|
| **Numeric** | Numbers double each tier (×1 → ×2 → ×4 → ×8) |
| **Coverage** | More targets/instances (1 → 2 → all → area) |
| **Additive** | New capability each tier (base → +effect → +effect → ultimate) |
| **Threshold** | Binary unlocks (L10: X; L20: Y; L30: Z) |

---

## Class Entries

### ORE (Fortitude)

**Warlord** (Ore×Striker): Armored front-line destroyer who shatters enemy formations.
*Earthshatter* [Conditional: requires melee attack] — Passive: First melee attack/round ignores armor equal to FOR mod. Active: Ground slam knocks prone in 3m. Scales: numeric (armor bypass) + coverage (radius).
- L10: Armor bypass applies to first TWO attacks
- L20: Ground slam also staggers (lose 1 AP)
- L30: All melee attacks ignore armor, slam radius 6m

**Knight** (Ore×Guardian): Immovable armored defender who holds the line.
*Iron Resolve* [Consistent] — Passive: DR = FOR mod on first hit/round. Active: Redirect attack on ally within 5m to self.
- L10: DR on first TWO hits/round
- L20: Redirect provokes opportunity attack on original attacker
- L30: DR on ALL hits, redirect is free action

**Arbalist** (Ore×Hunter): Siege specialist with devastating ranged attacks.
*Piercing Shot* [Consistent] — Passive: Ranged attacks ignore cover equal to PRC mod. Active: Penetrating bolt hits all in line.
- L10: Also ignore armor equal to PRC mod
- L20: Penetrating bolt pins targets (immobilized 1 round)
- L30: Can shoot through walls up to 1m thick

**Saboteur** (Ore×Skirmisher): Infiltrator who undermines structures and defenses.
*Structural Weakness* [Conditional: requires construct/fortification target] — Passive: +2 damage vs constructs/fortifications. Active: Touch weakens structure (halve HP).
- L10: +4 damage, weakness spreads 3m
- L20: Instant breach on walls, +6 damage
- L30: Collapse structures with touch, +10 damage

**Apothecary** (Ore×Mender): Practical healer using mundane medicine and mineral remedies.
*Stone Salve* [Consistent] — Passive: Healing grants temp HP equal to WIS mod. Active: Create poultice that heals over 3 rounds.
- L10: Temp HP equals WIS mod × 2, poultice cures poison
- L20: Also cures disease, temp HP lasts until rest
- L30: Poultice grants regeneration (heal 5/round for 1 min)

**Sentinel** (Ore×Warden): Unbreakable guardian of territory or people.
*Earthbind* [Consistent] — Passive: Enemies within 3m move at half speed. Active: Root target in place for 1 round.
- L10: Radius 5m, root lasts 2 rounds
- L20: Root also silences, radius 7m
- L30: Radius 10m, root also disarms and prevents teleportation

**Artificer** (Ore×Analyst): Craftsman who builds devices and improves equipment.
*Structural Analysis* [Consistent] — Passive: Instantly know object's material, quality, weaknesses. Active: Repair item 50% HP.
- L10: Repair 100%, can identify magical properties
- L20: Create temporary items (1 hour duration)
- L30: Permanently enhance equipment (+1 tier)

**Marshal** (Ore×Speaker): Military commander who leads through discipline and presence.
*Rally Point* [Consistent] — Passive: Allies within 10m gain +1 DEF. Active: Grant ally extra action.
- L10: +2 DEF, radius 15m
- L20: Can grant extra action to two allies
- L30: +3 DEF, extra action to all allies in radius 1/combat

---

### TIDE (Precision)

**Marauder** (Tide×Striker): Relentless water-aspected warrior who wears enemies down.
*Eroding Strikes* — Passive: Each hit on same target reduces their DEF by 1 (max FOR mod). Active: Reset erosion, deal bonus damage equal to stacks. Scales: numeric (max stacks) + additive (also reduces ATK).

**Bulwark** (Tide×Guardian): Adaptive defender who flows around attacks.
*Fluid Defense* — Passive: +2 DEF vs second+ attacks from same enemy. Active: Redirect missed attack to adjacent enemy. Scales: coverage (attacks) + threshold (L20: reflect ranged).

**Deadeye** (Tide×Hunter): Peerless marksman with supernatural accuracy.
*Perfect Aim* — Passive: Ignore range penalties. Active: Called shot with no penalty. Scales: threshold (L10: ignore cover; L20: ricochet; L30: shoot through walls).

**Corsair** (Tide×Skirmisher): Maritime raider equally deadly on ship or shore.
*Sea Legs* — Passive: Ignore difficult terrain, can't be knocked prone. Active: Swing/leap 10m to any point. Scales: numeric (distance) + additive (also pull enemy → also swap positions).

**Wellspring** (Tide×Mender): Healer who channels life-giving waters.
*Living Water* — Passive: Heals cleanse 1 condition automatically. Active: Create healing spring (3 uses, 2d6 each). Scales: numeric (uses, healing) + additive (also cures curse).

**Maelstrom** (Tide×Warden): Controller who manipulates water and weather.
*Undertow* — Passive: Enemies you damage move 2m in direction you choose. Active: Pull all enemies within 10m toward center. Scales: coverage (radius) + additive (also damage → also prone).

**Diviner** (Tide×Analyst): Seer who reads patterns in water and fate.
*Scrying* — Passive: See through any water within 100m. Active: Ask one yes/no question about the future. Scales: threshold (L10: see past; L20: multiple questions; L30: change one answer).

**Siren** (Tide×Speaker): Enchanter whose voice carries irresistible power.
*Compelling Voice* — Passive: +2 to all social rolls, voice carries twice normal distance. Active: Single target must obey one-word command. Scales: additive (more words → multiple targets → area).

---

### PYRE (Might)

**Berserker** (Pyre×Striker): Rage-fueled destroyer who grows stronger as battle continues.
*Burning Fury* — Passive: +1 damage per round of combat (max MIG mod). Active: Enter rage: +4 damage, -2 DEF for combat. Scales: numeric (bonuses) + threshold (L20: immune fear; L30: can't die until rage ends).

**Immolator** (Pyre×Guardian): Defender wreathed in protective flames.
*Flame Shield* — Passive: Attackers in melee take FOR mod fire damage. Active: Burst flames 3m, pushing enemies back. Scales: numeric (damage) + coverage (radius).

**Bombardier** (Pyre×Hunter): Explosive specialist who rains destruction from range.
*Explosive Shot* — Passive: Ranged attacks deal splash damage to adjacent enemies. Active: Lob explosive (3m radius, 2d6). Scales: numeric (damage, radius) + additive (also burning → also knockback).

**Hellion** (Pyre×Skirmisher): Chaos agent who spreads fire and confusion.
*Trail of Flames* — Passive: Leave fire trail when moving (1d6 to followers). Active: Teleport to any fire within 20m. Scales: coverage (trail size) + threshold (L20: create fire at range; L30: become fire).

**Firekeeper** (Pyre×Mender): Healer who uses controlled burning for purification.
*Cauterize* — Passive: Heals also remove bleeds and poisons. Active: Burn wound closed (2d6 heal + end one condition). Scales: numeric (healing) + additive (also grants fire resist → also cure curse).

**Pyromancer** (Pyre×Warden): Master of flame who controls the battlefield with fire.
*Pyroclasm* — Passive: Immune to own fire; your fire persists 1 extra round. Active: Reshape existing fire within 20m. Scales: coverage (fire size) + additive (detonate → wall → firestorm).

**Alchemist** (Pyre×Analyst): Transmuter who creates compounds and catalyzes reactions.
*Volatile Mixture* — Passive: Create 3 basic compounds per rest. Active: Combine compounds for explosive/acidic/adhesive effect. Scales: threshold (L10: 5 compounds; L20: advanced formulas; L30: philosopher's stone).

**Firebrand** (Pyre×Speaker): Agitator who ignites passion and rebellion.
*Incite* — Passive: +2 to Intimidation; immune to fear effects. Active: Enrage target (attacks nearest creature). Scales: coverage (targets) + additive (also allies gain +2 ATK → mass frenzy).

---

### GALE (Agility)

**Tempest** (Gale×Striker): Storm-powered warrior striking with wind and lightning.
*Lightning Strike* — Passive: First attack each round has advantage. Active: Dash 10m and attack all adjacent enemies. Scales: numeric (distance, damage) + coverage (enemies hit).

**Vanguard** (Gale×Guardian): Mobile defender who intercepts threats across the battlefield.
*Wind Wall* — Passive: +2 DEF vs ranged attacks. Active: Dash to ally and grant them +4 DEF until your next turn. Scales: coverage (allies) + additive (also reflect ranged → also counterattack for ally).

**Windrunner** (Gale×Hunter): Swift archer who never stays in one place.
*Zephyr Shot* — Passive: Can move before and after ranged attacks. Active: Fire while moving full speed, no penalty. Scales: threshold (L10: ignore wind; L20: guide arrows around cover; L30: arrow returns).

**Dervish** (Gale×Skirmisher): Whirling dancer of blades in constant motion.
*Blade Dance* — Passive: +1 DEF per enemy within 3m. Active: Spin attack hitting all adjacent. Scales: numeric (damage) + additive (also move between each hit → also immune to AoO).

**Monk** (Gale×Mender): Wind-breathing healer who channels qi through meditation.
*Breath of Life* — Passive: Restore 1 HP per round to self while not attacking. Active: Transfer HP to ally (your HP to them). Scales: numeric (amount) + additive (also transfer conditions → also revive).

**Stormcaller** (Gale×Warden): Weather-shaper who commands wind and lightning.
*Eye of the Storm* — Passive: Calm 5m radius around you (no weather effects). Active: Call lightning on target (3d6, stun on crit). Scales: numeric (damage) + coverage (chain to nearby → area storm).

**Tactician** (Gale×Analyst): Combat analyst who reads chaos and finds advantage.
*Battle Sense* — Passive: See enemy HP% and next intended action. Active: Grant ally reroll. Scales: threshold (L10: see 2 turns ahead; L20: see all enemies; L30: predict crits) + numeric (rerolls).

**Herald** (Gale×Speaker): Swift messenger whose words travel faster than sound.
*Voice of Wind* — Passive: Voice carries 100m clearly. Active: Send message to anyone within 1km. Scales: numeric (range) + threshold (L20: receive reply; L30: two-way conversation at any distance).

---

### RADIANCE (Presence)

**Paladin** (Radiance×Striker): Holy warrior smiting evil with divine fury.
*Smite* [Conditional: requires attack] — Passive: +2 damage vs undead, demons, aberrations. Active: Next attack deals +PRE mod radiant damage.
- L10: +4 damage vs evil, smite blinds on hit
- L20: Smite banishes extraplanar creatures (WIL save)
- L30: +8 damage, smite disintegrates undead/demons

**Templar** (Radiance×Guardian): Sacred defender who shields the faithful.
*Aegis of Light* [Consistent] — Passive: Allies within 3m gain +1 to saves. Active: Absorb damage meant for ally (you take it instead).
- L10: Radius 5m, +2 to saves
- L20: Absorbed damage halved
- L30: Radius 10m, +3 to saves, reflected absorbed damage back

**Inquisitor** (Radiance×Hunter): Truth-seeker who hunts lies and corruption.
*Reveal Truth* [Consistent] — Passive: Know when someone within 10m lies. Active: Force target to answer truthfully (WIL save).
- L10: Compel speech (target must answer), radius 15m
- L20: Reveal hidden (see invisible, disguised)
- L30: Dispel all illusions in 30m radius

**Crusader** (Radiance×Skirmisher): Mobile holy warrior leading charges against darkness.
*Blazing Charge* [Conditional: requires movement] — Passive: First attack after moving 5m+ deals +2 radiant. Active: Charge 10m through enemies, damaging all.
- L10: +4 radiant after movement, charge heals allies passed
- L20: Charge distance 15m, damage doubled
- L30: +8 radiant, charge grants allies extra movement

**Cleric** (Radiance×Mender): Divine healer channeling light to mend and protect.
*Lifesense* [Consistent] — Passive: Sense ally HP/conditions within 30m. Active: Heal 2d6+WIS at 10m range.
- L10: Range 20m, also remove one condition
- L20: Mass heal (all allies in 10m radius)
- L30: Full restore (heal to max, remove all conditions)

**Beacon** (Radiance×Warden): Living lighthouse whose light banishes darkness.
*Illuminate* [Consistent] — Passive: Emit bright light 10m (can suppress). Active: Dispel magical darkness in 20m.
- L10: Light radius 20m, dispel radius 30m
- L20: Light damages undead (WIS mod/round)
- L30: Create daylight even underground, undead flee or burn

**Oracle** (Radiance×Analyst): Prophet who sees truth through divine revelation.
*Foresight* [Consistent] — Passive: Can't be surprised; +2 Initiative. Active: Glimpse immediate future (advantage on next roll).
- L10: +4 Initiative, can warn ally (they gain advantage)
- L20: Reroll any roll (yours or ally's)
- L30: Change declared action after seeing result of enemy's action

**Prophet** (Radiance×Speaker): Divine voice who speaks with authority of the heavens.
*Word of Authority* [Consistent] — Passive: +2 to Persuasion; voice can't be silenced magically. Active: Command (one word, WIL save or obey).
- L10: +4 Persuasion, command up to 3 words
- L20: Command multiple targets (up to PRE mod)
- L30: Mass command (all enemies in 20m, complex instructions)

---

### SHROUD (Willpower)

**Reaper** (Shroud×Striker): Death-aspected killer who harvests souls.
*Death's Harvest* [Conditional: requires killing blow] — Passive: Killing blow restores HP equal to WIL mod. Active: Mark for death (+50% damage, you or ally).
- L10: Heal WIL mod × 2 on kill, also gain temp HP equal to heal
- L20: Kill on marked target heals all allies within 10m
- L30: Extra attack on kill, mark bonus increases to +100%

**Revenant** (Shroud×Guardian): Undying defender who refuses to fall.
*Undying* [Conditional: triggers at 0 HP] — Passive: First time reduced to 0 HP per combat, return to 1 HP. Active: Ignore death for 1 round (act at 0 or below).
- L10: Triggers twice per combat
- L20: Act normally while at negative HP
- L30: Cannot be killed while Undying is active (3 rounds)

**Wraith** (Shroud×Hunter): Ghostly sniper who strikes from shadow.
*Phase Shot* [Consistent] — Passive: Ranged attacks ignore non-magical cover. Active: Become incorporeal for 1 round (immune to physical).
- L10: Can see invisible, ignore magical cover
- L20: Can attack while incorporeal
- L30: Phase at will (free action), attacks while phased deal +50% damage

**Assassin** (Shroud×Skirmisher): Shadow-striker who vanishes after kills.
*Death's Shadow* [Conditional: requires stealth] — Passive: +50% damage from stealth. Active: Stealth check after kill (free action).
- L10: +75% damage from stealth, hide is always free action
- L20: Auto-hide on any kill, can hide after any hit (not just kills)
- L30: Attacks from stealth auto-crit, phase for 1 round after kill

**Witch** (Shroud×Mender): Dark healer who trades blood for power.
*Blood Price* [Consistent] — Passive: Can heal using your HP (1:1.5 ratio). Active: Curse wound (target can't be healed, 3 rounds).
- L10: Ratio improves to 1:2, curse lasts 5 rounds
- L20: Can drain HP from cursed targets, transfer conditions
- L30: Link life totals with willing ally (damage split evenly)

**Hexer** (Shroud×Warden): Curse-layer who weakens enemies from within.
*Hex* [Consistent] — Passive: Enemies you damage have -1 to next roll. Active: Major curse (disadvantage all rolls, 3 rounds).
- L10: Passive becomes -2, curse radius 5m
- L20: Curse also halves movement, afflicts additional targets
- L30: Doom curse (save or die after 3 rounds)

**Necromancer** (Shroud×Analyst): Scholar of death who commands the fallen.
*Command Dead* [Conditional: requires corpses] — Passive: Sense undead within 100m. Active: Raise corpse as minion (stats = half original).
- L10: Minion stats = 75% original, control 2 minions
- L20: Create elite undead (full stats), control 4 minions
- L30: Raise as intelligent undead, control unlimited lesser undead

**Harbinger** (Shroud×Speaker): Doomsayer whose words carry the weight of fate.
*Pronounce Doom* [Consistent] — Passive: +2 Intimidation; immune to fear. Active: Declare death sentence (target -2 all rolls vs you).
- L10: +4 Intimidation, doom penalty -3
- L20: Doomed targets cannot heal, penalty -4
- L30: Doom penalty -6, crit against doomed target = instant death

---

### ANIMA (Wisdom)

**Savage** (Anima×Striker): Primal warrior who channels beast fury.
*Feral Rage* — Passive: Unarmed/natural attacks deal +WIS mod damage. Active: Partial transformation (claws 2d6, bite 1d8). Scales: numeric (damage) + additive (also armor → also pounce → full beast form).

**Beastmaster** (Anima×Guardian): Defender bonded with animal companions.
*Pack Bond* — Passive: Animal companion (stats = level ÷ 2). Active: Companion intercepts attack on you or ally. Scales: threshold (L10: two companions; L20: dire beast; L30: legendary beast or swarm).

**Ranger** (Anima×Hunter): Wilderness hunter tracking prey through any terrain.
*Predator's Mark* — Passive: Track marked target across any distance. Active: Mark prey (+2 attack and damage vs them). Scales: numeric (bonus) + additive (also see through their eyes → also share senses with allies).

**Prowler** (Anima×Skirmisher): Wild stalker who moves unseen through nature.
*Nature's Cloak* — Passive: Advantage on Stealth in natural terrain. Active: Become invisible while motionless in nature. Scales: threshold (L10: move slowly while invisible; L20: full movement; L30: invisible in any terrain).

**Druid** (Anima×Mender): Nature priest who heals through primal magic.
*Nature's Bounty* — Passive: Healing in natural terrain gains +WIS mod. Active: Grow healing herbs (3 uses, 2d6 each). Scales: numeric (uses, healing) + additive (also cure poison → also regeneration → also resurrection).

**Shaman** (Anima×Warden): Spirit-speaker who commands nature and the unseen.
*Spirit Ward* — Passive: Spirits warn of danger (+2 Perception). Active: Command local spirits (entangle/distract/guide). Scales: coverage (area) + additive (also damage → also possess → also greater spirits).

**Sage** (Anima×Analyst): Keeper of ancient lore and natural wisdom.
*Ancient Knowledge* — Passive: Read any language; know creature weaknesses on sight. Active: Commune with nature (ask 3 questions about area). Scales: numeric (questions) + threshold (L20: commune with spirits; L30: glimpse creation's memory).

**Chieftain** (Anima×Speaker): Tribal leader who commands through primal authority.
*Alpha Presence* — Passive: Beasts won't attack unless provoked. Active: Command animal (WIS save or obey). Scales: coverage (targets/HD limit) + threshold (L20: also monstrous beasts; L30: any creature with animal intelligence).

---

### AETHER (Intellect)

**Battlemage** (Aether×Striker): War-wizard who blends magic and martial prowess.
*Arcane Striker* — Passive: Melee attacks can deal force damage instead. Active: Teleport 5m and attack with +INT mod damage. Scales: numeric (distance, damage) + additive (also dispel on hit → also spell on hit).

**Aegis** (Aether×Guardian): Shield-mage who protects with barriers of force.
*Force Barrier* — Passive: +INT mod to DEF vs first attack each round. Active: Create wall of force (10m long, blocks all). Scales: numeric (size, duration) + threshold (L20: dome; L30: selective permeability).

**Warlock** (Aether×Hunter): Pact-mage who strikes from afar with eldritch power.
*Eldritch Blast* — Passive: Ranged spell attack (INT mod d6, 30m). Active: Empower blast (+1d6 per 2 levels). Scales: numeric (damage, range) + additive (also push → also curse on hit → also chain).

**Magus** (Aether×Skirmisher): Spell-blade who weaves magic into movement.
*Spellstep* — Passive: Can cast while moving, no concentration penalty. Active: Short teleport (10m) + cantrip. Scales: numeric (distance) + coverage (bring allies) + additive (also full spell).

**Mystic** (Aether×Mender): Reality-bender who heals by rewriting what happened.
*Temporal Mend* — Passive: Heals restore HP as it was 1 round ago. Active: Rewind single injury (restore HP lost from one attack). Scales: numeric (amount) + threshold (L20: rewind conditions; L30: rewind death within 1 round).

**Spellbreaker** (Aether×Warden): Anti-mage who disrupts and counters magic.
*Nullify* — Passive: +2 saves vs magic; sense magic within 20m. Active: Counterspell (INT vs caster INT). Scales: threshold (L10: dispel ongoing; L20: silence area; L30: antimagic zone).

**Arcanist** (Aether×Analyst): Pure scholar of magical theory and application.
*Spell Mastery* — Passive: Reduce spell costs by 1 (min 1). Active: Cast spell you've witnessed once. Scales: threshold (L10: two witnessed; L20: modify spells +1 effect; L30: create new spells).

**Enchanter** (Aether×Speaker): Mind-mage who bends will and perception.
*Charm* — Passive: +2 to social vs those who can hear you. Active: Suggest action (WIL save). Scales: additive (also dominate → also mass suggestion → also rewrite memories).
