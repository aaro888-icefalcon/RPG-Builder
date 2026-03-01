# Repository Maintenance Policy

This policy keeps the phase-oriented runtime architecture stable.

## 1) Placement rules for net-new files

1. Choose operating lane first:
   - Runtime content belongs in `runtime/phases/[N-phase]/`.
   - Development/quality/planning guidance belongs in `development/*`.
2. Phase-first placement — all content goes into the owning phase:
   - Phase 1 (`1-context-loading`): references (hard-rules, gm-protocol, creation), lore, state loading
   - Phase 2 (`2-action-interpretation`): action classification, CLI selection
   - Phase 3 (`3-resolution`): mechanics code and data in domain sub-groups:
     - `skills/core/` — dice, conditions, character
     - `skills/combat/` — combat, creatures, behavior, techniques
     - `skills/exploration/` — scenes, adventure, pressure
     - `skills/social/` — NPCs, factions, diplomacy
     - `skills/downtime/` — downtime tables
     - `skills/world-building/` — world tick, moves
   - Phase 4 (`4-narrative`): narrative translation, templates, narration references
   - Phase 5 (`5-persistence`): state persistence, turn receipts
   - Phase 6 (`6-validation`): response gate, validators
3. Entry point scripts stay in `runtime/scripts/`; domain modules live in Phase 3.
4. Phase governance files:
   - Phase CLAUDE.md: operating instructions (< 40 lines)
   - Phase index.md: skill inventory and reference map
   - Phase skills/*.md: instruction files that REFERENCE canonical sources
   - NEVER duplicate canonical content in skill files — reference with §section pointers

## 2) Requirements when moving files

When moving or renaming a doc:
- Update all hub links in the same change.
- Add a pointer stub if the source path is high-traffic.
- Update phase index.md pages.
- Re-run docs structure, reference freshness, and canonical reference validators.

## 3) Structural PR checklist

- [ ] Scope is limited to one architectural surface or a documented wave.
- [ ] Canonical runtime anchors remain intact (`turn-loop.md`, `play-runbook.md`, `scripts/CLAUDE.md`).
- [ ] Required hubs/indexes remain present.
- [ ] No broken canonical-hub links.
- [ ] `python scripts/validate_reference_freshness.py` passes.
- [ ] `python scripts/validate_docs_structure.py` passes.
- [ ] `python scripts/validate_canonical_references.py` passes.
- [ ] If applicable, stale artifact check passes (`git diff --exit-code -- .`).
- [ ] Phase skill files reference canonical sources, not duplicate them.
- [ ] Phase CLAUDE.md files are under 40 lines.
- [ ] New skills placed in correct phase directory.
- [ ] If this PR completes an execution plan, plan moved to `ongoing-plans/plans/completed/`.
- [ ] If this is a structural PR, check `ongoing-plans/analysis/` for stale artifacts and delete them.

## 4) Regression prevention

- Prefer small-batch structural PRs.
- Avoid introducing duplicate canonical paths for the same topic.
- Treat failing structure checks as merge blockers.

## 5) Content change checklist

For changes that add or modify game mechanics, lore, skills, or runtime behavior:

- [ ] Owning phase identified (1-6); new content placed in `runtime/phases/[N-phase]/`.
- [ ] References placed in phase-appropriate `references/` directory.
- [ ] Domain scripts/tables placed in `phases/3-resolution/skills/[DOMAIN]/scripts/` or `tables/`.
- [ ] Skill files reference canonical sources with §section pointers (relative for phase-local).
- [ ] Phase CLAUDE.md and index.md updated with new/changed skills.
- [ ] `phase-manifest.md` updated (cli_commands, references, hooks).
- [ ] Hook enforcement documented in skill's "Hooks That Enforce This" section.
- [ ] Script registry (`scripts/CLAUDE.md`) updated if new CLI commands.
- [ ] If state schema touched: full cross-cutting checklist applies. → `change-integration-checklist.md` §5
- [ ] `python runtime/tests/run_all_tests.py 1` passes.
- [ ] `python runtime/scripts/validate_reference_freshness.py` passes.
- [ ] `python runtime/scripts/validate_docs_structure.py` passes.
- [ ] `python runtime/scripts/validate_canonical_references.py` passes.
- [ ] If this change completes an execution plan, plan moved to `ongoing-plans/plans/completed/`.

> Full integration guide: `change-integration-checklist.md`
