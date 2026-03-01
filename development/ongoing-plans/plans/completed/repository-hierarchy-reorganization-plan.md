# Repository Hierarchy Reorganization Plan (Top-to-Bottom)

## Scope and intent

This plan responds to the requested structural cleanup goals:

1. Remove redundant nesting under `runtime/`.
2. Rename the effective gameplay package root to **`runtime/`** at repository top level.
3. Evaluate `.claude` runtime hooks/settings for retention vs deletion.
4. Place development docs in clearly discoverable root locations.
5. Tag every file by purpose and map to destination.

Companion inventory and purpose tags: `docs/development/file-purpose-tagging.csv`.

## Current-state diagnosis

- Current structure has a triple-layer nesting (`Claude Code` → `emergence-rpg-v45` → `emergence-rpg-v45`) that creates path churn, weak discoverability, and duplicate development docs in multiple places.
- Root-level `docs/development/` exists, but many development docs still also live in nested package docs, creating split authority.
- `.claude/hooks` are present and referenced by script registry as runtime guardrails; they should not be deleted blindly.

## Why development docs are split today

The repo evolved with a host-repo governance layer at root and an embedded content package under `Claude Code/...`; development docs were created in both places during migration planning, which caused duplication and cross-link drift.

## Target canonical hierarchy

```text
/
├─ AGENTS.md
├─ README.md
├─ runtime/                      # renamed from nested gameplay package
│  ├─ AGENTS.md
│  ├─ CHANGELOG.md
│  ├─ docs/
│  │  ├─ index.md
│  │  ├─ runtime/
│  │  └─ development/
│  ├─ references/
│  ├─ lore/
│  ├─ tables/
│  ├─ assets/
│  ├─ scripts/
│  ├─ tests/
│  └─ .claude/                   # keep only if runtime hooks are still used
├─ docs/
│  └─ development/               # repo-level planning, migration, governance docs
├─ inventory/                    # keep temporarily, later archive under docs/development/inventory/
├─ .github/
└─ archives/                     # optional: retired zips/backups/snapshots
```


## Implementation status (current repository state)

- Phase 1 completed: gameplay package moved to top-level `runtime/` and redundant nested wrappers removed.
- Phase 3 partial: runtime hooks retained under `runtime/.claude/hooks/`; local settings file removed.
- Phase 4 partial: legacy zip/classes docs and backup artifact relocated under `archives/`.
- Phase 5 partial: added required surface indexes for `references`, `lore`, `assets`, `tables`, and `tests`.

## File purpose labels

All files were tagged in `docs/development/file-purpose-tagging.csv` using these labels:

- `governance`, `navigation`, `development_doc`, `design_doc`, `execution_plan_doc`,
- `runtime_doc`, `mechanics_reference`, `lore_reference`, `lookup_table`,
- `runtime_script`, `test_suite`, `test_fixture`, `runtime_hook`, `ci_config`,
- `archive_blob`, `backup_artifact`, `legacy_reference`, `unclassified`.

## Execution plan (ordered)

### Phase 0 — Freeze and safety checks

- Freeze merges to avoid path conflict churn.
- Generate a baseline link report and test report.
- Add temporary compatibility notes in README before moving files.

Done criteria:
- Baseline tests pass.
- Baseline link map captured in repo artifact.

### Phase 1 — Lift package to `runtime/` and delete redundant wrappers

- Move `Claude Code/emergence-rpg-v45/emergence-rpg-v45/**` → `runtime/**`.
- Move `Claude Code/emergence-rpg-v45/AGENTS.md` → `runtime/AGENTS.md`.
- Remove empty `Claude Code/emergence-rpg-v45/` wrapper.
- Evaluate whether `Claude Code/` is still needed after moves; if empty except archival files, remove it.

Done criteria:
- No live code/docs remain under `runtime/`.
- All references updated to `runtime/...` paths.

### Phase 2 — Resolve development-doc authority and eliminate duplication

- Keep **repo governance/planning** in root `docs/development/`.
- Keep **runtime implementation/developer docs** in `runtime/docs/development/`.
- For duplicated docs (same topic in root and runtime), choose a single canonical owner and replace the other with a short pointer stub (one release cycle), then remove stubs.

Done criteria:
- Each development topic has one canonical source.
- No conflicting duplicated docs remain.

### Phase 3 — `.claude` decision

Evaluate each file in `runtime/.claude`:

- Keep hooks if they are actively referenced by workflow and script registry.
- Remove local-only settings (`settings.local.json`) if machine-specific and not required.
- If hooks are kept, document them in `runtime/docs/development/scripts/index.md` with maintenance owner.

Delete `.claude` entirely only if:
- hooks are not called by actual runtime workflow, and
- no contributor tooling depends on them.

Done criteria:
- Explicit keep/delete decision documented per `.claude` file.

### Phase 4 — Remove stale artifacts and archives

- Move `archives/emergence-rpg-v45.zip` and `*.bak` files to `archives/` or delete after verification.
- Merge `archives/classes-v45.md` into `runtime/references/classes.md`; then delete legacy file.

Done criteria:
- No backup or orphan archive files in active runtime paths.

### Phase 5 — Linkage and discoverability repair

- Add missing index files for required surfaces:
  - `runtime/references/index.md`
  - `runtime/lore/index.md`
  - `runtime/assets/index.md`
  - `runtime/tables/index.md`
  - `runtime/tests/index.md`
- Rewire root `README.md` and `runtime/docs/index.md` to these indexes.

Done criteria:
- Every lower-level doc is reachable from top-level routers in ≤3 clicks.

### Phase 6 — Validation and cutover

Run and pass:

- full link checker / reference freshness validator,
- state validator,
- smoke tests (`tests/run_all_tests.py 1`),
- CI path sanity (`git diff --check`, no stale generated artifacts).

Done criteria:
- All checks pass with new paths.
- Old path references reduced to zero.

## Redundant-folder deletion candidates

After Phase 1 and Phase 4 completion:

- `runtime/` (delete)
- `Claude Code/` (delete if empty / only archived content moved)
- duplicate development-doc branches that become pointer stubs and expire

## Risks and mitigations

- **Risk:** broken imports/links after move.  
  **Mitigation:** scripted path rewrite + link validation + tests.
- **Risk:** losing runtime enforcement from `.claude` hooks.  
  **Mitigation:** explicit keep/delete matrix before removal.
- **Risk:** duplicate docs causing conflicting guidance.  
  **Mitigation:** canonical-owner table and temporary pointer stubs.

## Recommended immediate next PRs

1. PR-A: path move to `runtime/` + link rewrites only.
2. PR-B: doc authority cleanup + index creation + linkage fixes.
3. PR-C: `.claude` keep/delete decision + archival cleanup.
