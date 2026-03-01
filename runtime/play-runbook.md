# Runtime Runbook

Operational procedures for running game turns with high fidelity.

## Two-phase runtime interaction (required)

1. **Scene report only**: describe current state, pressure, and options.
2. **Pause for explicit player action**: do not execute mechanics yet.
2b. **Route via master router**: run the action classification CLI command.
    - If `DEVELOPMENT:` prefix -> skip to development mode.
    - Read `required_cli` from output. These are the commands to execute in step 4.
3. **Validate input provenance**: `python scripts/validate_turn_input.py --input-json <turn_input.json>`
4. **Resolve mechanics + persist** only after provenance validation passes.

If explicit player action is absent, halt turn progression and return scene/options only.

## Run a turn

1. Open `scripts/CLAUDE.md` and identify required runtime-safe commands.
2. Execute the strict protocol in `turn-loop.md`.
3. Produce a turn receipt with:
   - Commands run
   - Key outputs
   - Canonical state delta summary
   - Derived outputs updated
   - Validation status
   - RNG seed (if used)

## Validate state

- Command: `python scripts/validate_state.py <state-path>`
- Must pass both pre-turn and post-turn.

## Regenerate derived outputs

- Use only documented commands from `scripts/CLAUDE.md`.
- If regeneration tooling is missing, halt runtime and log a development-mode gap.

## Apply migrations/backfills

- Not allowed in runtime mode.
- Switch to development mode under overall `CLAUDE.md` with explicit approval gates.

## Rollback a broken turn

- If post-validation fails, treat turn as rejected.
- Restore last known good canonical state snapshot.
- Create a development-mode follow-up task for remediation.

## Troubleshoot common failures

- **Missing script contract**: classify as `unknown` in script registry and block runtime use.
- **CLI arg/schema mismatch**: update docs or implementation in a separate development PR.
- **Non-deterministic output drift**: verify seed capture and stable ordering in generation logic.

## Cohesion rule

Runtime mode may execute only scripts listed in `scripts/CLAUDE.md` with `runtime-safe: yes`.
