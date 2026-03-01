# Ongoing Plans — Planning Workspace

Scope: `development/ongoing-plans/`

## Rules

1. All new planning and analysis documents go here.
2. Temporary or generated planning artifacts go in `plans/` or `analysis/`.
3. Delete generated planning docs once implemented — rely on Git history.
4. Do not create backup copies; use Git history instead.

## Structure

- `plans/active/`          → In-flight execution plans being implemented
- `plans/completed/`       → Finished or canceled plans (short-lived archive)
- `plans/execution-plan-template.md` → Standard template for new plans
- `analysis/`              → Audits, inventories, and exploratory analysis
- `analysis/inventory/`    → Archived pre-restructuring inventory (most artifacts deleted)

## Plan Lifecycle

1. **Create**: use the execution plan template. Place in `plans/active/`.
2. **Implement**: reference the plan during development workflow steps 3-6.
3. **Complete**: when all exit criteria are met, move from `active/` to `completed/` as part of workflow step 7 (PR summary). Add a completion date.
4. **Delete**: completed plans are short-lived. Delete from `completed/` once the next session confirms no regressions. Rely on Git history for archival.

## Analysis Artifact Lifecycle

Analysis artifacts have no active/completed folders — they live flat in `analysis/`.

- **Structural audits** (inventories, linkage audits, file classifications): delete when the repo structure they describe changes materially. They are snapshots, not durable references.
- **Feature/design analyses** (e.g., turn narration analysis): keep until the feature is implemented or explicitly abandoned, then delete.
- **Review trigger**: when a structural PR lands, check whether any analysis artifacts are now stale and delete them.
