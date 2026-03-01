# Execution Plan: Runtime Scrub — Blank RPG Template

- **Owner:** Claude / aaro888-icefalcon
- **Status:** Complete
- **Start Date:** 2026-02-24
- **Target Date:** 2026-02-24
- **Related Decision Logs:** None

## Objective

Strip all Emergence: The Exile game-specific content from `runtime/` while preserving the development infrastructure and the engine's pipeline architecture. The result is a blank RPG template: a working 6-phase GM pipeline with validation, CLI dispatch, and turn-loop machinery — but no lore, no game mechanics, no domain scripts, and no game-specific tests. A new game can be built on top by populating the empty phase directories with new content.

## Scope

### In scope

- Delete all game-specific lore, references, skills, scripts, tables, and tests from `runtime/`
- Delete all domain Python scripts and table modules (keep only CLI dispatcher + validators)
- Genericize engine governance files (CLAUDE.md files, turn-loop, play-runbook, phase-manifest)
- Reset `state.json` to a minimal engine-only blank state
- Genericize `state.schema.json` to remove Emergence-specific enums/values
- Update all `index.md` navigation files to reflect post-scrub inventory
- Ensure validators still pass on the blank template
- Tag the pre-scrub commit for easy restoration via git history

### Out of scope

- Changes to `development/` (kept intact per user request)
- Changes to `.claude/` hooks infrastructure
- Changes to `.github/` CI configuration (may need follow-up if CI references deleted files)
- Designing or populating a new game — this plan creates the blank canvas only
- Modifying `archives/` (pre-existing archived content)

---

## Milestones

### M0: Safety — Tag current state
Git-tag the current HEAD so the full Emergence game can be restored from history at any time.

### M1: Delete game-specific content
Bulk-remove all Emergence-specific files from every phase, plus game-specific tests and build files.

### M2: Genericize engine files
Strip game-specific language from governance/navigation files that remain. Convert to template placeholders.

### M3: Reset state and schema
Produce a minimal blank `state.json` and genericized `state.schema.json`.

### M4: Update navigation and registries
Rebuild all `index.md` files, `phase-manifest.md`, and `scripts/CLAUDE.md` to reflect the scrubbed state.

### M5: Validate
Run all applicable validators to confirm the blank template is internally consistent.

---

## Task Breakdown

### M0: Safety

- [ ] Create git tag `pre-scrub-emergence-v1` on current HEAD

### M1: Delete game-specific content

**Phase 1 — Context Loading:**
- [ ] Delete `runtime/phases/1-context-loading/lore/` (entire directory — setting, geography, factions, creatures, culture, locations)
- [ ] Delete `runtime/phases/1-context-loading/references/` (hard-rules, gm-protocol, creation, awakening, aspects-archetypes) — **NOTE:** `hard-rules.md` content is game-specific; the *concept* of hard rules lives in runtime/CLAUDE.md and will be converted to a template
- [ ] Delete `runtime/phases/1-context-loading/skills/` (lore-loading, new-game-setup, scene-context, state-loading)
- [ ] Delete `runtime/phases/1-context-loading/assets/` (world-state-template)

**Phase 2 — Action Interpretation:**
- [ ] Delete `runtime/phases/2-action-interpretation/references/` (cli-reference with game-specific command list)
- [ ] Delete `runtime/phases/2-action-interpretation/skills/` (action-classification, cli-selection, mechanical-classification)

**Phase 3 — Resolution (largest deletion):**
- [ ] Delete `runtime/phases/3-resolution/skills/core/` (entire domain — mechanics, attributes, classes, conditions, magic, scripts, references)
- [ ] Delete `runtime/phases/3-resolution/skills/combat/` (entire domain — combat rules, enemies, scripts, tables)
- [ ] Delete `runtime/phases/3-resolution/skills/exploration/` (entire domain — scene, equipment, scarcity, scripts, tables)
- [ ] Delete `runtime/phases/3-resolution/skills/social/` (entire domain — diplomacy, NPCs, factions, scripts, tables)
- [ ] Delete `runtime/phases/3-resolution/skills/downtime/` (entire domain — rest, training, crafting, tables)
- [ ] Delete `runtime/phases/3-resolution/skills/world-building/` (entire domain — world-tick, faction evolution, scripts, tables)

**Phase 4 — Narrative:**
- [ ] Delete `runtime/phases/4-narrative/references/` (narration-examples, narration-mappings)
- [ ] Delete `runtime/phases/4-narrative/assets/` (character-sheet-template, current-scene-template)
- [ ] Delete `runtime/phases/4-narrative/skills/` (narration, combat-display)

**Phase 5 — Persistence:**
- [ ] Delete `runtime/phases/5-persistence/skills/` (state-persistence — game-specific persistence procedures)
- [ ] Delete `runtime/phases/5-persistence/turn-receipt-v2-template.json`

**Phase 6 — Validation:**
- [ ] Delete `runtime/phases/6-validation/skills/` (pre-turn-validation, reference-freshness, response-gate — these encode game-specific validation expectations)

**Root runtime files:**
- [ ] Delete `runtime/character-sheet.md` (Emergence-specific display template)

**Tests:**
- [ ] Delete all balance test files (`balance_*.py`, `identity_test_*.py`, `viability_test_*.py`, `compression_test_*.py`, `death_rate_test_*.py`, `scaling_cliff_test.py`, `stress_test_*.py`, `cross_archetype_balance.py`, `class_fantasy_audit.py`, `balance_playtest.py`)
- [ ] Delete game-specific build files (`builds/pyre_striker.py`, `builds/all_archetypes_pyre.py`, `builds/atlas_128.json`)
- [ ] Delete game-specific unit tests that test Emergence mechanics (`test_classify_action.py`, `test_standard_array.py`, `test_xp_levelup.py`, `test_turn_narration_renderer.py`, `test_receipt_contract_fields.py`, `test_cli_seed_reproducibility.py`, `test_turn_requires_user_action_provenance.py`, `unified_entity_test.py`)
- [ ] Delete `runtime/tests/builds/__init__.py` if directory is empty
- [ ] Delete exploration test report (`exploration-mechanics-test-report.md`)

**Scripts:**
- [ ] Delete `runtime/scripts/render_turn_narrative.py` (renders Emergence-specific narration)

### M2: Genericize engine files

**runtime/CLAUDE.md:**
- [ ] Strip game-specific Hard Rules content → replace with placeholder list directing new game to define its own
- [ ] Strip Narrative Principles (alienation, scarcity, gritty tone) → replace with placeholder
- [ ] Strip Forced Consequences wording → keep the concept as a template
- [ ] Replace "Emergence: The Exile" campaign references with `[GAME_NAME]` placeholder
- [ ] Keep: Fidelity Pledge, Truth Model, GM Pipeline, Entry Points, No Silent Repairs, Determinism

**runtime/turn-loop.md:**
- [ ] Replace any Emergence-specific references with generic language (mostly already generic — audit and confirm)

**runtime/play-runbook.md:**
- [ ] Replace any Emergence-specific references with generic language (mostly already generic — audit and confirm)

**Phase CLAUDE.md files (phases 1–6):**
- [ ] Strip game-specific content from each phase CLAUDE.md
- [ ] Keep pipeline instructions and contract definitions
- [ ] Add placeholder notes like `<!-- Define your game's [X] content here -->`

**Phase index.md files (phases 1–6):**
- [ ] Clear content inventory tables (no files to list)
- [ ] Keep structural headers and purpose descriptions
- [ ] Add template guidance for what content belongs in each phase

**runtime/phases/3-resolution/skills/ directory:**
- [ ] After deleting all 6 domain subdirectories, leave an empty `skills/` with a brief index.md explaining the domain structure pattern for new games

### M3: Reset state and schema

**state.schema.json:**
- [ ] Remove Emergence-specific attribute names from the `attributes` definition → make attributes an open object or use generic placeholders
- [ ] Remove game-specific enum values (stance names, scene types can stay as they're generic RPG concepts)
- [ ] Replace `"Emergence: The Exile"` title/description with `[GAME_NAME]` placeholder
- [ ] Keep all structural definitions (resource_pool, clock, chronicle, etc.) — these are generic RPG engine constructs

**state.json:**
- [ ] Reset to minimal valid blank state:
  - `schema_version`: keep current
  - `content_version`: reset to `"0.0.1"`
  - `character`: minimal placeholder with generic attribute names matching updated schema
  - `campaign.name`: `"[GAME_NAME]"`
  - `chronicle`: empty
  - `world_situation`: minimal empty structure
  - All arrays: empty
  - All world/faction/NPC/location data: cleared

### M4: Update navigation and registries

- [ ] Update `runtime/index.md` — reflect post-scrub file inventory
- [ ] Update `runtime/phases/index.md` — reflect empty phases with template guidance
- [ ] Update `runtime/phases/phase-manifest.md` — remove all game-specific CLI/hook/script entries; keep phase structure
- [ ] Update `runtime/scripts/CLAUDE.md` — remove deleted scripts from registry; keep validator entries
- [ ] Update `runtime/scripts/index.md` (if exists) — reflect reduced script set
- [ ] Update `runtime/tests/CLAUDE.md` — reflect reduced test suite
- [ ] Update `runtime/tests/index.md` — reflect reduced test suite
- [ ] Strip `emergence_cli.py` of game-specific subcommand imports — keep dispatcher skeleton with placeholder registration pattern

### M5: Validate

- [ ] Run `python runtime/scripts/validate_state.py runtime/state.json` — must pass
- [ ] Run `python runtime/scripts/validate_docs_structure.py` — must pass (or document expected failures from reduced content)
- [ ] Run `python runtime/tests/run_all_tests.py 1` — remaining tests must pass (test_state_schema.py against new blank state)
- [ ] Manual review: confirm no broken references in remaining markdown files

---

## Validation

| Check | Command | Expected |
|-------|---------|----------|
| State schema validation | `python runtime/scripts/validate_state.py runtime/state.json` | Pass |
| Docs structure | `python runtime/scripts/validate_docs_structure.py` | Pass or documented exceptions |
| Remaining tests | `python runtime/tests/run_all_tests.py 1` | Pass |
| No orphan references | Manual grep for deleted file paths in remaining .md files | Zero hits |

## Risks and Mitigations

- **Risk:** Validators reference deleted files or game-specific content → **Mitigation:** Run validators after each milestone; fix references iteratively
- **Risk:** `emergence_cli.py` imports deleted domain modules and crashes → **Mitigation:** Strip imports in M4; verify with `python runtime/scripts/emergence_cli.py --help`
- **Risk:** CI jobs fail because they expect game-specific tests → **Mitigation:** Out of scope for this plan but flagged; `.github/` may need a follow-up PR
- **Risk:** `.claude/` hooks reference deleted files → **Mitigation:** Audit hooks after scrub; this is technically out of scope but should be checked
- **Risk:** Remaining tests import deleted modules → **Mitigation:** Delete tests that depend on game-specific code (covered in M1)

## Exit Criteria

1. `runtime/` contains only engine infrastructure: pipeline architecture, CLI dispatcher skeleton, validators, turn-loop contract, and blank state
2. No Emergence-specific lore, mechanics, classes, enemies, or narrative content remains in `runtime/`
3. All remaining `index.md` and `CLAUDE.md` files accurately describe the post-scrub state
4. `state.json` validates against `state.schema.json`
5. `development/` directory is completely untouched
6. A git tag exists for restoring the pre-scrub Emergence game
7. The template is ready for a new game to be built on top by populating phase directories
