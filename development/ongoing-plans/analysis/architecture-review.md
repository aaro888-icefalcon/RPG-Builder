# Emergence Exile Repository Architecture Review

## Layered structure

1. **Repository governance layer (root):** `README.md` routes users by mode (development vs runtime), while root `AGENTS.md` defines development-loop constraints.
2. **Embedded game package:** canonical gameplay content currently lives under `runtime/`.
3. **Design-target architecture:** `docs/design-docs/repo-architecture.md` defines intended top-level contracts (`docs/runtime`, `docs/development`, `references`, `lore`, `tables`, `assets`, `scripts`, `tests`) and allowed artifact types.

## Core architectural surfaces inside the gameplay package

- **Runtime workflow contracts:** `docs/workflows/turn-loop.md` and `docs/workflows/play-runbook.md` define operational sequencing and runtime acceptance gates.
- **Script execution surface:** `docs/scripts/index.md` is the canonical script/command registry, including runtime safety classification.
- **Mechanics engine implementation:** `scripts/emergence_cli.py` is the unified JSON CLI entrypoint; feature modules in `scripts/*.py` implement mechanics domains (combat, character, faction, NPC, scenes, etc.).
- **Canonical rules and setting data:** `references/` holds mechanical source-of-truth docs; `lore/` holds narrative/world context; `tables/` provides structured lookup tables.
- **Validation and quality gates:** `scripts/validate_state.py` enforces state-shape requirements; CI runs smoke tests and validator/regen checks from `.github/workflows/ci.yml`.

## Data and control flow

1. Operator follows runtime turn-loop contract.
2. State is validated (`validate-state`).
3. Mechanics are executed through `emergence-cli` subcommands.
4. Canonical state is updated and validated again.
5. Turn receipt and derived artifacts are produced per workflow docs.

This produces a **docs-first + CLI-enforced** architecture where behavior contracts are documented canonically and executed by a single scripted entrypoint with validation guardrails.

## Architectural strengths

- Clear governance split between runtime and development modes.
- Single command surface (`emergence-cli`) reduces mechanics drift.
- Explicit validator + CI jobs protect schema and derived artifact freshness.

## Current structural caveat

The package is still nested under `runtime/`; architecture docs already describe normalization toward cleaner canonical top-level folders.
