# 50 - Reorganization Backlog (for Phase 2 Planning)

> Status: Written pre-restructuring. Items annotated with post-restructuring disposition.

## Prioritized Items

1. **Repair `docs/index.md` broken links** — COMPLETED
   - Resolved by restructuring: `runtime/index.md` and phase `index.md` files replace the old docs index.

2. **Create root-level navigation README** — COMPLETED
   - Resolved: root `CLAUDE.md` + `runtime/index.md` + `development/index.md` serve as entry points.

3. **Define canonical ownership by domain** — COMPLETED
   - Resolved by phase-oriented layout: each phase directory has `CLAUDE.md` + `index.md` declaring ownership. Domain folders replaced by `runtime/phases/3-resolution/skills/{domain}/`.

4. **Reduce orphan docs through hub relinking** — COMPLETED
   - Resolved: phase `index.md` files + `phase-manifest.md` link all content. Every reference/lore/skill doc reachable from its phase hub.

5. **Normalize naming conventions and path taxonomy** — COMPLETED
   - Resolved by phase-oriented naming: `{phase-number}-{phase-name}/` at top level, `skills/{domain}/` within phase 3.

6. **Audit potential duplicate topical docs** — OPEN
   - May still apply: some references under `runtime/references/` may overlap with symlinked copies in `runtime/phases/`. Worth a follow-up audit to verify no drift between originals and phase copies.

## Exit Criteria (Original)
- Zero broken internal markdown links from canonical hubs. — Largely achieved.
- Every markdown page reachable from at least one index/hub. — Achieved.
- Root README points to authoritative entry points. — Achieved via `CLAUDE.md`.
