# Reference Freshness Matrix

This table tracks ownership and review cadence for core runbooks that must remain aligned with active code paths and CLI behavior.

| Reference doc | Owner | Review cadence | Last verified commit | Notes |
|---|---|---|---|---|
| `phases/1-context-loading/references/hard-rules.md` | GM Protocol Maintainer | Every release + weekly | `d3a35f3524372b22b541d00c83e86aed347845c1` | Non-negotiable procedures and checklists |
| `phases/1-context-loading/references/gm-protocol.md` | Narrative Systems Lead | Every release + biweekly | `d3a35f3524372b22b541d00c83e86aed347845c1` | Full adjudication protocol and move guidance |
| `phases/2-action-interpretation/references/cli-reference.md` | CLI Maintainer | On every command change + weekly | `d3a35f3524372b22b541d00c83e86aed347845c1` | Command contract and examples |
| `phases/3-resolution/skills/combat/references/combat.md` | Combat Systems Owner | On combat logic changes + biweekly | `d3a35f3524372b22b541d00c83e86aed347845c1` | Combat loop, AP economy, and turn structure |
| `phases/3-resolution/skills/core/references/conditions.md` | Survival/Conditions Owner | On condition logic changes + biweekly | `d3a35f3524372b22b541d00c83e86aed347845c1` | Condition handling, damage-over-time, recovery |
| `schemas/state.schema.json` | Schema Owner | On every schema change | `c2f67eaf0470193352cde6bc9a1229ba8c771075` | State shape definition (v5.0.0) — see §5 of change-integration-checklist.md |
| `scripts/validate_state.py` | Schema Owner | On every schema/validator change | `c2f67eaf0470193352cde6bc9a1229ba8c771075` | 5-layer state validator |

## Freshness workflow

1. Run `git rev-parse HEAD` and record the value used for verification.
2. Confirm each core runbook includes a "Last verified against code commit" header block.
3. If any runbook is stale, update the runbook first or add a dated gap note here before session start.
