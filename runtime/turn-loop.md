# Turn Loop Contract (Runtime)

This document defines the strict turn protocol for runtime play.

## Preconditions

- Canonical script registry reviewed: `scripts/CLAUDE.md`
- Required runtime commands are marked `runtime-safe: yes`
- Canonical state file path is known (typically `state.json`)

## Mandatory sequence

1. **Capture turn input and route via master router**
   - Record player intent verbatim.
   - If player message starts with `DEVELOPMENT:`, skip to development mode — no CLI required.
   - Otherwise, run the master router CLI command to classify the action.
   - The router's output determines which subcommand(s) to execute in step 4.
   - Do not execute mechanics until explicit player action payload is captured.
2. **Validate turn input provenance**
   - Run `validate-turn-input` against the action payload JSON.
   - Halt if `player_action_source` is not `user_verbatim` or `action_confirmed` is not `true`.
3. **Pre-validate state**
   - Run `validate-state` against canonical state.
   - If validation fails, halt turn.
4. **Apply mechanics via CLI**
   - Execute only documented runtime-safe `emergence-cli` command(s).
   - Do not substitute hand-rolled mechanics.
5. **Persist canonical updates**
   - Write resulting canonical state updates.
   - Record RNG seed if randomness was used.
6. **Regenerate derived outputs**
   - Update any derived artifacts required by current workflow.
   - Never hand-edit derived artifacts.
7. **Post-validate state**
   - Re-run `validate-state`.
   - If post-validation fails, reject turn and flag remediation in development mode.
8. **Write turn receipt**
   - Persist command list, high-level outputs, files touched, checks run/passed, and seed.

## Acceptance rule

A turn is accepted only if all eight steps complete successfully in order.

## Halt conditions

- Missing required script in `scripts/CLAUDE.md`
- Script marked `runtime-safe: no` or `unknown`
- Script failure/non-zero status
- Missing/invalid player action provenance payload
- Schema validation failure
- Any ambiguous mechanic not resolved by canonical references
