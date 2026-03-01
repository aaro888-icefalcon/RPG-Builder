# Math Assumptions — Authoritative Balance Reference

This document codifies all mathematical assumptions underlying the combat balance system. All formulas, hit rate targets, and resource budgets reference this document as the source of truth.

---

## 1. Core Resolution

- **System:** 2d6 + modifier vs DC
- **Average roll:** 7
- **Target hit rate (PC → at-level standard enemy, Balanced stance, raw build):** 42-58%
- **Target hit rate (PC → at-level standard enemy, focused build):** 70-85%
- **Target hit rate (enemy → average PC):** 35-50%
- **Graze band:** DC-1 to DC-2 (deals half damage)

---

## 2. PC Attack Progression

**PC ATK = Attribute Mod + Weapon Tier ATK + Weapon Focus Tree**

| Level | Attr Mod | Weapon Tier ATK | Weapon Focus | Total (raw) | Total (focused) |
|-------|----------|-----------------|-------------|-------------|-----------------|
| 1 | +2 | +0 (T1) | +0 | **+2** | **+2** |
| 5 | +4 | +1 (T2) | +2 | **+5** | **+7** |
| 10 | +5 | +2 (T3) | +3 | **+7** | **+10** |
| 15 | +6 | +3 (T4) | +4 | **+9** | **+13** |
| 20 | +7 | +4 (T5) | +4 | **+11** | **+15** |

---

## 3. PC Defense Progression

**PC DEF = 10 + AGI Mod + Armor (base + tier) + Shield + DEF Talents**

| Level | Avg DEF | Glass DEF | Tank DEF | Notes |
|-------|---------|-----------|----------|-------|
| 1 | 11 | 11 | 14 | |
| 5 | 13 | 13 | 17 | |
| 10 | 15 | 14 | 20 | Tank: med T3 + h.shield T1 + talent |
| 15 | 17 | 15 | 22 | Tank: heavy T3 + h.shield T2 + talent |
| 20 | 18 | 16 | 24 | Tank: heavy T4 + h.shield T3 + talent |

Note: v4.5.10 armor flattening reduced T4/T5 by 1-2 points. Tank DEF estimates use realistic (not max) equipment tiers.

---

## 4. Enemy Formulas

```python
# creature.py
attack = 3 + (level * 2) // 5     # +0.4/level
defense = 10 + (level * 2) // 5   # +0.4/level
base_hp = 24 + (level * 2)
damage = 3 + level
```

| Level | ATK | DEF | HP | DMG |
|-------|-----|-----|-----|-----|
| 1 | +3 | 10 | 26 | 4 |
| 5 | +5 | 12 | 34 | 8 |
| 10 | +7 | 14 | 44 | 13 |
| 15 | +9 | 16 | 54 | 18 |
| 20 | +11 | 18 | 64 | 23 |

---

## 5. Hit Rate Matrix

**PC → Standard Enemy (Balanced stance):**

| Lv | Raw ATK | DEF | Need | P(hit) | Focused ATK | Need | P(hit) |
|----|---------|-----|------|--------|-------------|------|--------|
| 1 | +2 | 10 | 8+ | 41.7% | +2 | 8+ | 41.7% |
| 5 | +5 | 12 | 7+ | 58.3% | +7 | 5+ | 83.3% |
| 10 | +7 | 14 | 7+ | 58.3% | +10 | 4+ | 91.7% |
| 15 | +9 | 16 | 7+ | 58.3% | +13 | 3+ | 97.2% |
| 20 | +11 | 18 | 7+ | 58.3% | +15 | 3+ | 97.2% |

**Standard Enemy → PC:**

| Lv | ATK | Avg DEF | P(hit) | Glass DEF | P(hit) | Tank DEF | P(hit) |
|----|-----|---------|--------|-----------|--------|----------|--------|
| 1 | +3 | 11 | 41.7% | 11 | 41.7% | 14 | 8.3% |
| 5 | +5 | 13 | 41.7% | 13 | 41.7% | 17 | 2.8% |
| 10 | +7 | 15 | 41.7% | 14 | 58.3% | 20 | 0% |
| 15 | +9 | 17 | 41.7% | 15 | 72.2% | 22 | 0% |
| 20 | +11 | 18 | 58.3% | 16 | 83.3% | 24 | 0% |

---

## 6. Stance DPR Budget

| Stance | Ratio to Balanced | Key Trade-off |
|--------|-------------------|---------------|
| Balanced | 1.00x | No trade-off (anchor) |
| Aggressive | 1.3-1.5x | 0 RP, -2 DEF |
| Focused | 1.1-1.3x | 2 AP, no move, 0 RP, -2 DEF |
| Mobile | ~1.0x | +1 DEF, +4m move, free disengage |
| Defensive | 0.3-0.5x | +4 DEF, 2 RP, crit immunity |

---

## 7. Equipment Assumptions

### Weapons

| Tier | Name | Level Range | DMG Mod | ATK Mod | Attr Req Increase |
|------|------|-------------|---------|---------|-------------------|
| T1 | Common | 1-4 | +0 | +0 | Base |
| T2 | Uncommon | 5-9 | +2 | +1 | +2 |
| T3 | Rare | 10-14 | +4 | +2 | +4 |
| T4 | Epic | 15-19 | +6 | +3 | +6 |
| T5 | Legendary | 20+ | +8 | +4 | +8 |

Base weapon damage: Light=6, Medium=8, Heavy=10, Bow=8.

### Armor (v4.5.10 — tier bonuses flattened to +1/tier)

| Type | Base DEF | Tier 2 | Tier 3 | Tier 4 | Tier 5 |
|------|----------|--------|--------|--------|--------|
| Light | +2 | +3 | +4 | +5 | +6 |
| Medium | +4 | +5 | +6 | +7 | +8 |
| Heavy | +6 | +7 | +8 | +9 | +10 |

### Shields (v4.5.10 — tier scaling added)

| Tier | Light Shield | Heavy Shield |
|------|-------------|-------------|
| T1 | +1 | +2 |
| T2 | +1 | +2 |
| T3 | +2 | +3 |
| T4 | +2 | +3 |
| T5 | +3 | +4 |

---

## 8. Resource Pool Budgets

### HP
- Formula: `20 + (MIG x 2) + (FOR x 2) + (Lv x 3)`
- 4-round standard fight: enemy depletes 30-50% HP
- Boss fight (8 rounds): threatens Bloodied (50%)

### Stamina
- Formula: `10 + (FOR x 2) + AGI + Lv`
- 4-round fight budget: 60-80% of pool using T1-T2 techniques
- Per technique (actual averages): T1=2.14, T2=4.00, T3=6.10
- 3-fight day: martial goes negative on fight 3 with mixed rotation (intentional — forces degradation)

### Mana (v4.5.10 — formula + recovery rebalanced)
- Formula: `10 + (INT x 2) + WIL + Lv` (was `WIL x 2`, now `WIL x 1` — matches Stamina structure)
- 3 fights with 2 short rests: deplete to ~17%
- Short rest recovers **33%** (was 50%)
- Per spell (actual averages): T1=2.22, T2=4.33, T3=7.24
- L5 Caster pool: 65 (was 79)

### Composure
- Formula: `10 + (PRE x 2) + WIL + Lv`
- Non-speaker: reaches Shaken (50%) after 2 tough fights with ally casualties
- Speaker: sustains 3-4 encounters per rest
- Universal pressure sources (v4.5.10): ally drops, ally dies, outnumbered, prolonged combat, horrific scenes, failed death saves

---

## 9. Technique Assumptions

| Tier | DPR vs Basic | AP | Stamina (avg) | Mana (avg) | ATK Mod | Source Data |
|------|-------------|-----|--------------|-----------|---------|------------|
| T1 | +3 avg (+20-30%) | 1 | 2.14 (range 1-4) | 2.22 (range 1-3) | +0 to +1 | 60 combat + 51 magic techniques |
| T2 | +4.6 avg (+40-60%) | 1-2 | 4.00 (range 2-5) | 4.33 (range 2-6) | +0 to +2 | from forms-combat-expanded.md |
| T3 | +6.3 avg (+80-120%) | 2-3 | 6.10 (range 4-8) | 7.24 (range 5-10) | +0 to +2 | and forms-magic-expanded.md |
| T4 | Mostly passive | — | 6.00 (2 active) | 5.00 (1 active) | +0 to +3 | 97-98% passives |

Only 6.7% of combat techniques grant +hit bonuses (16/240).

---

## 10. Talent ATK/DEF Budget

| Tree | T1 | T2 | T3 | T4 |
|------|-----|-----|-----|-----|
| Weapon Focus (ATK) | +1 | +2 | +3 | +4 |
| Weapon Spec (DMG) | — | +2 | +4 | +6 |
| Shield (DEF) | +1 | +2 | +3 | — |
| Evasive (DEF) | +1 | +2 | +3 | — |
| Flanking (ATK, conditional) | +2 | — | — | — |

---

## 11. Skill Assumptions

| Rarity | Damage | AP | Resource | DPR vs Basic | Acquisition |
|--------|--------|-----|----------|-------------|-------------|
| Common | 1d6+mod | 1 | 2-3 | +0-10% | Standard 1% |
| Uncommon | 2d6+mod | 1-2 | 4-5 | +20-30% | Elite 5% |
| Rare | 3d6+mod | 2 | 6-8 | +40-60% | Boss 20% |
| Epic | 4d6+mod | 2-3 | 10-12 | +70-100% | Quest reward |
| Legendary | 5d6+mod | 3 | 15-18 | +100-150% | Legendary event |

Expected count: 1-2 skills by L10, 3-5 by L20.
