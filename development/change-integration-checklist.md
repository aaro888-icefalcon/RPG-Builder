# Change Integration Checklist

Operational guide for integrating changes into the runtime system. Use this checklist whenever the development workflow (root `CLAUDE.md` §Workflow) reaches steps 1, 2, or 4.

Related docs:
- Folder contracts: `design-docs/repo-architecture.md`
- File placement & PR checklists: `repo-maintenance-policy.md`
- Phase manifest format: `runtime/phases/phase-manifest.md`

---

## §1 — Change Type Classification

Identify the owning phase and affected surfaces before writing any code.

### Phase Directory Reference

| Phase | Directory | Content |
|---|---|---|
| 1 | `phases/1-context-loading/` | State loading, lore, scene context, hard-rules, gm-protocol |
| 2 | `phases/2-action-interpretation/` | Action classification, CLI selection |
| 3 | `phases/3-resolution/` | All game mechanics — 6 domain sub-groups |
| 4 | `phases/4-narrative/` | Narrative translation, combat display |
| 5 | `phases/5-persistence/` | State updates, turn receipts |
| 6 | `phases/6-validation/` | Response gate, validators |

### Phase 3 Domain Sub-Groups

| Domain | Directory | Scripts |
|---|---|---|
| core | `phases/3-resolution/skills/core/` | dice.py, conditions.py, character.py |
| combat | `phases/3-resolution/skills/combat/` | combat.py, creature.py, behavior.py, technique_registry.py |
| exploration | `phases/3-resolution/skills/exploration/` | scene.py, scene_pressure.py, adventure.py |
| social | `phases/3-resolution/skills/social/` | npc.py, faction.py, diplomacy.py |
| downtime | `phases/3-resolution/skills/downtime/` | (tables only) |
| world-building | `phases/3-resolution/skills/world-building/` | world_tick.py, moves.py |

### Decision Tree

```
What are you changing?

  A game rule or mechanic
    → Which Phase 3 domain does it serve?
      Domain-specific (e.g., attack bands, creature stats)
        → phases/3-resolution/skills/[DOMAIN]/references/
      Cross-cutting (used by 3+ domains, e.g., hard-rules, gm-protocol)
        → phases/1-context-loading/references/
    → Does it need new CLI support?
        → Also update domain scripts + scripts/CLAUDE.md

  World/setting/lore content
    → All lore lives in phases/1-context-loading/lore/

  A phase workflow or skill
    → Create/edit phases/[N-phase]/skills/[name].md
    → Skill files REFERENCE canonical sources — never duplicate

  Executable code (script logic)
    → Domain-specific (e.g., combat.py, behavior.py)
        → phases/3-resolution/skills/[DOMAIN]/scripts/
    → Entry-point scripts (CLI dispatcher, validators)
        → runtime/scripts/

  A lookup table or structured data
    → Domain-specific (e.g., behavior_tables.py)
        → phases/3-resolution/skills/[DOMAIN]/tables/

  A state schema change (fields, types, enums, required keys)
    → Update schemas/state.schema.json
    → Bump schema_version (APPROVAL GATE — confirm before proceeding)
    → Update validate_state.py if new validation rules needed
    → Update test_state_schema.py with new mutation tests
    → Update development/quality/state-schema-migration-notes.md
    → Update reference-freshness.md with new commit hash
    → See §5 below for full schema change checklist

  A hook or validator
    → .claude/hooks/ + .claude/settings.json

  A template or player-facing artifact
    → phases/4-narrative/assets/ or phases/5-persistence/assets/

  Development docs only
    → development/*
```

**Phase-first placement principle:** All content goes INTO the owning phase directory. Entry point scripts stay at `scripts/` root; domain modules live in Phase 3 sub-groups.

---

## §2 — Runtime Integration Checklist (7 Touchpoints)

For every change that affects how the game runs, check which touchpoints apply and update them. Not every change needs all 7.

```
- [ ] 1. Skill file
         Created/updated in phases/[N-phase]/skills/
         9-section template: Summary, Prerequisites, Steps, Canonical References,
         Scripts, Hooks That Enforce This, Output Format, Common Failures

- [ ] 2. Phase index.md
         Skill listed in inventory table
         Columns: Skill | File | CLI Commands | Trigger

- [ ] 3. Phase CLAUDE.md
         Skill listed in routing table + trigger in pre-response checklist

- [ ] 4. phase-manifest.md
         cli_commands, references, hooks lists updated for owning phase

- [ ] 5. Hook enforcement
         Skill's "Hooks That Enforce This" section lists all applicable hooks

- [ ] 6. Script registry
         scripts/CLAUDE.md updated if new CLI subcommands added

- [ ] 7. Tests
         runtime/tests/ updated if new mechanics or CLI subcommands introduced
```

### Which touchpoints apply?

| Change type | Touchpoints |
|---|---|
| New skill (e.g., add crafting) | All 7 |
| Mechanic edit (e.g., change damage formula) | 1, 5, 7 |
| New CLI subcommand | 4, 6, 7 |
| Hook addition/change | 4, 5 |
| Lore addition (no mechanical effect) | None (unless it feeds a skill) |
| Reference-only edit (rule clarification) | 1 (update skill's Canonical References if pointer changed) |
| State schema change | 7 + §5 checklist |

---

## §3 — Scope Accounting

"Major surfaces" referenced in root `CLAUDE.md` §Guardrails. If a change touches more than 2, split into phased PRs.

```
1. State schema       — state.json structure changes
2. Phase references   — phases/*/references/*.md (canonical rules)
3. Phase scripts      — phases/3-resolution/skills/*/scripts/*.py (mechanics code)
4. Phase skills       — phases/*/skills/*.md, phase CLAUDE.md/index.md (workflows)
5. Validation/hooks   — .claude/hooks/*, .claude/settings.json
6. Phase manifest     — phases/phase-manifest.md (system config)
7. Output rendering   — phases/4-narrative/assets/*, derived templates
8. Documentation      — development/*
```

---

## §4 — Content Placement Rules (Phase-First)

| Content type | Canonical home | Example |
|---|---|---|
| Phase-specific rule/mechanic | `phases/3-resolution/skills/[DOMAIN]/references/` | combat.md in skills/combat/references/ |
| Phase-specific script | `phases/3-resolution/skills/[DOMAIN]/scripts/` | combat.py in skills/combat/scripts/ |
| Phase-specific table | `phases/3-resolution/skills/[DOMAIN]/tables/` | behavior_tables.py in skills/combat/tables/ |
| Phase skill/workflow | `phases/[N-phase]/skills/` | Operational playbook — references, never duplicates |
| Cross-cutting rule | `phases/1-context-loading/references/` | hard-rules.md, gm-protocol.md |
| World lore | `phases/1-context-loading/lore/` | Geography, factions, creatures |
| Narrative references | `phases/4-narrative/references/` | narration-mappings.md |
| Player-facing templates | `phases/4-narrative/assets/` or `phases/5-persistence/assets/` | Character sheet, turn receipt |

**Key rule:** Skill files REFERENCE canonical sources with `§section` pointers — they never duplicate rule content.

---

## §5 — Cross-Cutting Artifact Checklist

Some artifacts span multiple phases and don't fit the phase-first placement model. These **cross-cutting artifacts** require both development-side documentation updates AND runtime-side wiring so they remain discoverable during play.

**Principle:** When a cross-cutting artifact changes, update the development docs that govern it AND the runtime docs that reference it. If only one side is updated, the change is incomplete.

### State Schema Changes

The state schema is the primary cross-cutting artifact. It touches validation, persistence, and every phase that reads state.

**Approval gate:** `schema_version` bumps require explicit confirmation before proceeding (root `CLAUDE.md` §Guardrails).

```
Development-side:
- [ ] 1. schemas/state.schema.json — add/remove/modify fields, types, enums, required keys
- [ ] 2. scripts/validate_state.py — new validation rules, all 5 layers consistent
- [ ] 3. tests/test_state_schema.py — mutation tests for new rules
- [ ] 4. development/quality/state-schema-migration-notes.md — upgrade steps
- [ ] 5. development/quality/reference-freshness.md — update commit hash

Runtime-side:
- [ ] 6. runtime/CLAUDE.md — Entry Points table reflects schema contract
- [ ] 7. phases/5-persistence/CLAUDE.md — Key Resources references schema
- [ ] 8. phases/phase-manifest.md — Phase 5 references list includes schema

Validation:
- [ ] 9. python runtime/scripts/validate_state.py runtime/state.json
- [ ] 10. python runtime/scripts/validate_docs_structure.py
- [ ] 11. python runtime/scripts/validate_canonical_references.py
```

### When does this checklist apply?

| Change | Applies? |
|---|---|
| Add/remove a top-level required key | Full checklist |
| Change a field type or enum values | Full checklist |
| Add a new $def or modify an existing one | Items 1-3, 9-11 |
| Fix a validator bug (no schema change) | Items 2, 3, 9-11 |
| Update migration notes only | Item 4 only |

### Future cross-cutting artifacts

If a new artifact emerges that spans 3+ phases and doesn't fit phase-first placement, add a section here following the same pattern: development-side updates, runtime-side wiring, validation checks.
