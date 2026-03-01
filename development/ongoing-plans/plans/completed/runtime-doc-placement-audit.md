# Runtime Documentation Placement Audit (Revised via Practice Run-Throughs)

## Purpose

Audit documentation placement with a practical lens:

1. What documents are naturally surfaced when following the **development lane**?
2. What documents are naturally surfaced when following the **runtime lane**?
3. Which runtime docs should be moved to repository-level development docs now, and which should stay where they are?

## Practice run-through method

I performed two navigation walkthroughs using existing entrypoints and linked lane docs.

### Development walkthrough

Path followed:

1. `README.md` → "Documentation index" (`runtime/docs/index.md`)
2. `runtime/docs/index.md` → "Development START-HERE" (`runtime/docs/development/START-HERE.md`)
3. `runtime/docs/development/START-HERE.md` linked surfaces:
   - `runtime/docs/development/repo-structure-breakdown.md`
   - `runtime/docs/development/file-placement-recommendations.md`
   - `runtime/docs/development/file-placement-matrix.csv`
   - `runtime/docs/development/reorganization-implementation-plan.md`
   - `runtime/docs/design-docs/README.md`
   - `runtime/docs/exec-plans/active/README.md`
   - `runtime/docs/quality/README.md`
   - `runtime/docs/security/README.md`

### Runtime walkthrough

Path followed:

1. `README.md` → "Play runbook" (`runtime/docs/workflows/play-runbook.md`) and "Turn loop workflow" (`runtime/docs/workflows/turn-loop.md`)
2. `runtime/docs/runtime/START-HERE.md` links to:
   - `runtime/docs/workflows/turn-loop.md`
   - `runtime/docs/workflows/play-runbook.md`
   - `runtime/docs/scripts/index.md`
   - `runtime/references/hard-rules.md`
   - `runtime/references/cli-reference.md`
   - `runtime/references/gm-protocol.md`

## What the walkthroughs changed in recommendations

### Key observation

The repo currently treats `runtime/docs/index.md` and runtime anchors (`workflows/*`, `scripts/index.md`) as canonical navigation for both lanes. Moving those immediately would create churn against the current canonical map and existing links.

### Revised conclusion

- **Move/merge development-process docs first** (low runtime risk).
- **Do not move runtime canonical anchors yet** (`runtime/docs/index.md`, `runtime/docs/workflows/*`, `runtime/docs/scripts/index.md`).
- If root-level docs hubs are desired, add them as **thin pointers first**, then migrate in a later phase after link graph cleanup.

## Recommended moves from `runtime/` to `docs/development/` (Phase 1)

These are development-focused and surfaced primarily in development walkthroughs.

| Current path | Recommended path | Priority | Why |
| --- | --- | --- | --- |
| `runtime/docs/design-docs/README.md` | `docs/development/design-docs/README.md` | High | Development architecture/design artifact. |
| `runtime/docs/design-docs/decision-log-template.md` | `docs/development/design-docs/decision-log-template.md` | High | Development decision-process template. |
| `runtime/docs/design-docs/repo-architecture.md` | `docs/development/design-docs/repo-architecture.md` | High | Repository architecture governance document. |
| `runtime/docs/exec-plans/execution-plan-template.md` | `docs/development/exec-plans/execution-plan-template.md` | High | Development execution planning. |
| `runtime/docs/exec-plans/active/README.md` | `docs/development/exec-plans/active/README.md` | High | Active development planning surface. |
| `runtime/docs/exec-plans/completed/README.md` | `docs/development/exec-plans/completed/README.md` | High | Development planning history. |
| `runtime/docs/quality/README.md` | `docs/development/quality/README.md` | High | Development QA/validation guidance. |
| `runtime/docs/quality/ci-commands.md` | `docs/development/quality/ci-commands.md` | High | Development CI local equivalents. |
| `runtime/docs/quality/reference-freshness.md` | `docs/development/quality/reference-freshness.md` | Medium | Development doc-quality checks. |
| `runtime/docs/quality/state-schema-migration-notes.md` | `docs/development/quality/state-schema-migration-notes.md` | Medium | Development migration/change-management notes. |
| `runtime/docs/security/README.md` | `docs/development/security/README.md` | Medium | Development security posture guidance. |
| `runtime/docs/development/*` | `docs/development/*` | High | Semantically development-lane; consolidates split-brain. |

## Keep in `runtime/docs/` for now (canonical runtime anchors)

| Path | Keep reason |
| --- | --- |
| `runtime/docs/index.md` | Current canonical cross-lane router referenced by root README and canonical map. |
| `runtime/docs/workflows/turn-loop.md` | Runtime contract anchor and required turn protocol reference. |
| `runtime/docs/workflows/play-runbook.md` | Runtime operations anchor. |
| `runtime/docs/scripts/index.md` | Runtime safety registry and command contract anchor. |
| `runtime/docs/runtime/START-HERE.md` | Runtime onboarding lane entrypoint used by current nav model. |

## Root-level docs recommendation (revised)

Instead of immediate moves of runtime anchors, do this sequence:

1. Add `docs/index.md` as a lightweight pointer to `runtime/docs/index.md`.
2. Add `docs/runtime/START-HERE.md` as a pointer to `runtime/docs/runtime/START-HERE.md`.
3. Update root `README.md` only after pointer pages exist.
4. Perform hard moves of runtime anchors only in a dedicated follow-up after link validation and deprecation stubs.

This avoids breaking the currently documented canonical runtime map while still improving root discoverability.

## Risks and guardrails

- Main risk is authority ambiguity between `docs/development/` and `runtime/docs/development/` during transition.
- Use redirect/pointer stubs and explicit source-of-truth headers for each moved doc.
- Run link integrity + freshness checks in the same move PR.

## Decision checkpoint

Proceed with a **development-doc consolidation PR first** (runtime anchors untouched), then evaluate runtime-anchor relocation as a separate phase.
