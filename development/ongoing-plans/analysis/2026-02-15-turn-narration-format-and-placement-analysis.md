# Analysis: Turn Narration Plan Formatting, Placement, and Required File Changes

## Objective
Determine the best repository locations and document formatting boundaries for the turn-narration initiative, using agentic delineation between runtime execution and development planning.

## Agentic delineation (who owns what)

### 1) Runtime lane (play execution)
Owns operational truth for running turns and displaying outputs during play.

- **Must contain**: workflow steps, runtime-safe command contracts, receipt requirements, and response display obligations.
- **Must not contain**: implementation planning detail, migration sequencing, broad architecture alternatives.

Primary runtime files:
- `runtime/docs/workflows/turn-loop.md`
- `runtime/docs/workflows/play-runbook.md`
- `runtime/docs/scripts/index.md`

### 2) Development lane (design and rollout)
Owns implementation planning, architecture options, and change sequencing.

- **Must contain**: phased rollout, file-change matrix, testing strategy, acceptance criteria.
- **Must not contain**: alternate runtime rules that diverge from canonical runtime workflow.

Primary development files:
- `runtime/docs/development/ongoing-plans/analysis/*`

### 3) Reference lane (canonical guidance)
Owns reusable narration standards and style/system mappings consumed by runtime tooling.

- **Must contain**: consequence-to-prose mappings, prose style constraints, move-result narrative templates.
- **Must not contain**: runbook sequencing or implementation status.

Primary reference file (to add during implementation):
- `runtime/references/narration-mappings.md`

## Best formatting for plan content

Recommended structure for the active plan document:
1. Problem and constraints.
2. Output contract.
3. Architecture.
4. Validation and tests.
5. Rollout phases.
6. **File-change matrix (must/should/could)**.
7. Acceptance criteria.

Formatting rules:
- Keep normative statements in bullet/numbered lists.
- Use explicit path references for every required change.
- Separate **required** vs **optional** changes to avoid scope drift.
- Keep implementation details in plan file; keep rationale and alternatives in analysis file.

## Best location for new narration requirements

### Place in active plan
Use for decisions that directly govern upcoming implementation work:
- data contract,
- renderer behavior,
- test requirements,
- rollout order.

### Place in analysis doc
Use for supporting reasoning and tradeoffs:
- why chosen location is preferred,
- why specific files are mandatory,
- rejected alternatives.

### Place in runtime docs (during implementation PR)
Use for operator-facing instructions once behavior is real:
- runbook step insertion,
- turn-loop requirements,
- script registry runtime-safe declaration.

## Required file-change matrix (implementation)

## Must change
1. `runtime/scripts/render_turn_narrative.py` (new)
   - Implements deterministic narration artifact renderer.
2. `runtime/docs/scripts/index.md`
   - Registers renderer command and runtime-safe status.
3. `runtime/docs/workflows/play-runbook.md`
   - Adds explicit narration-generation and display stage.
4. `runtime/campaigns/<campaign>/turn_receipts/*.md` (template/behavior)
   - Records `narration_artifact_path`, seed, and renderer status.

## Should change
1. `runtime/docs/workflows/turn-loop.md`
   - If turn acceptance requires narration artifact for UX-complete turns.
   - Note: this is a turn-loop contract change and should be isolated/small.
2. `runtime/references/narration-mappings.md` (new)
   - Canonical prose + consequence mapping guidance.
3. `runtime/tests/test_turn_narration_renderer.py` (new)
   - Determinism + fidelity coverage.

## Could change
1. `runtime/references/gm-protocol.md`
   - Add concise pointer to narration renderer output conventions.
2. `runtime/docs/development/quality/ci-commands.md`
   - Add CI invocation for narration golden tests when introduced.

## Alternative placements considered

1. Put full narration rules in runbook only.
   - Rejected: mixes operator procedure with style canon and implementation details.
2. Put implementation plan details in references.
   - Rejected: references should remain canonical gameplay guidance, not project execution planning.
3. Keep all content in one giant active plan.
   - Rejected: harder maintenance; analysis churn obscures executable plan.

## Recommended PR decomposition

1. PR-A (renderer MVP): script + tests + plan-to-implementation scaffolding.
2. PR-B (runtime integration): runbook + script registry + receipt updates.
3. PR-C (quality hardening): golden files, CI wiring, and mapping refinements.

This decomposition keeps each PR within limited surfaces and makes review easier.

## Recommended first implementation PR (highest leverage)

If only one implementation PR is started now, prioritize:
1. `runtime/scripts/render_turn_narrative.py` (MVP for `scene` + `move`)
2. `runtime/tests/test_turn_narration_renderer.py` (determinism + fidelity)
3. `runtime/docs/scripts/index.md` (register command contract as runtime-safe when stable)

Defer runbook and turn-loop contract edits until renderer behavior is validated in tests, then integrate in the next PR.

## Priority corrections before implementation starts

Apply these corrections before PR-A coding begins:
1. Define receipt status fields (`turn_acceptance`, `narration_status`) to remove acceptance ambiguity.
2. Define a lightweight narration artifact schema (required headings + metadata keys).
3. Define deterministic ordering rules for state deltas and option ordering.
4. Define degraded-mode and consecutive-failure escalation policy in runbook language.
5. Define content redaction/sanitization boundary for player-facing narration.

These corrections reduce downstream rework and keep runtime behavior auditable.
