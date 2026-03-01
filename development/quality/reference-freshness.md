# Reference Freshness Matrix

This table tracks ownership and review cadence for core runbooks that must remain aligned with active code paths and CLI behavior.

| Reference doc | Owner | Review cadence | Last verified commit | Notes |
|---|---|---|---|---|
| `schemas/state.schema.json` | Schema Owner | On every schema change | `8d9636ce840a0ff382adeca8987fee2a1ea5fabd` | State shape definition (v6.0.0) |
| `scripts/validate_state.py` | Schema Owner | On every schema/validator change | `8d9636ce840a0ff382adeca8987fee2a1ea5fabd` | 5-layer state validator (game-agnostic) |

## Adding game-specific references

As you create game content, add rows to the table above for each reference doc you want to track. Use a 40-character git commit hash in the "Last verified commit" column.

Example row format:

    | `phases/1-context-loading/references/hard-rules.md` | GM Protocol Maintainer | Every release | `abc123...` | Your game's rules |

## Freshness workflow

1. Run `git rev-parse HEAD` and record the value used for verification.
2. Confirm each core runbook includes a "Last verified against code commit" header block.
3. If any runbook is stale, update the runbook first or add a dated gap note here before session start.
