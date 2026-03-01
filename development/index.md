# Development Documentation

Use this hub when you are **editing or improving** repository content, workflows, scripts, tests, or structure. All development documentation lives under this directory.

## Start Here

Two reading paths depending on your goal:

- **Understand the system:** [Design principles](./design-docs/design-principles.md) → [Folder contracts](./design-docs/repo-architecture.md)
- **Make changes:** [Change integration checklist](./change-integration-checklist.md) → [Maintenance policy](./repo-maintenance-policy.md) → [CI commands](./quality/ci-commands.md)

## Getting Started — Build Your Game

- [Guides index](./guides/index.md) — step-by-step guides for building on this template
- [Creating Game State](./guides/creating-game-state.md) — design your character model, world situation, and state schema
- [Creating Skills and Mechanics](./guides/creating-skills-and-mechanics.md) — write mechanics scripts and wire them into the pipeline
- [Creating Hooks](./guides/creating-hooks.md) — build Claude Code hooks for enforcement and context injection

## Architecture & Structure

- [Change integration checklist](./change-integration-checklist.md) — phase-first placement, 7-touchpoint integration, scope accounting
- [Repository architecture: folder contracts](./design-docs/repo-architecture.md) — canonical folder intent, content boundaries, allowed file types
- [Repository maintenance policy](./repo-maintenance-policy.md) — placement rules, move requirements, PR checklist

## Design Docs

- [Design docs index](./design-docs/index.md)
- [Design principles](./design-docs/design-principles.md) — governance philosophy (map-not-manual, enforcement tiers, dual-mode separation)
- [Repository architecture: folder intent](./design-docs/repo-architecture.md) — canonical folder contracts and content boundaries
- [Decision log template](./design-docs/decision-log-template.md)

## Quality & CI

- [Quality docs index](./quality/index.md)
- [CI commands](./quality/ci-commands.md) — how to run CI jobs locally
- [Reference freshness](./quality/reference-freshness.md) — tracked doc versions and commit hashes
- [State schema migration notes](./quality/state-schema-migration-notes.md) — v6.0.0 upgrade guide
- **Schema or cross-cutting changes?** → [Change integration checklist §5](./change-integration-checklist.md) for full cross-cutting artifact workflow

## Security

- [Security docs index](./security/index.md)

## Appendices

- [Appendices index](./appendices/index.md)
- [Classes v45 snapshot](./appendices/classes-v45.md) — archived class framework for migration reference

## Planning & Analysis

- [Ongoing plans index](./ongoing-plans/index.md) — plan lifecycle, analysis workspace
- Plans: [active](./ongoing-plans/plans/active/index.md) | [completed](./ongoing-plans/plans/completed/index.md) | [template](./ongoing-plans/plans/execution-plan-template.md)
- Analysis: [architecture review](./ongoing-plans/analysis/architecture-review.md) | [turn narration format analysis](./ongoing-plans/analysis/2026-02-15-turn-narration-format-and-placement-analysis.md)

## Operational Guardrails

- Keep changes scoped and test validated.
- Preserve canonical runtime anchors.
- Prefer moving with redirects/pointers over silent deletion.

## Adjacent Navigation

- Runtime hub: [runtime/index.md](../runtime/index.md)
- Runtime governance: [runtime/CLAUDE.md](../runtime/CLAUDE.md)
