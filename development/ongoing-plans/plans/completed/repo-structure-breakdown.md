# Repository Structure Breakdown: Current State vs Target Architecture

## Purpose
This document explains where the repository is now, why it feels disorganized, and what the target architecture will look like after the reorganization plan is executed.

## Current State (Observed)

### 1) Physical center of gravity is nested
The effective project root is:
- `runtime/`

This creates onboarding friction because the repository root currently does not act as a clear entrypoint for either development work or runtime play.

### 2) Large parallel domains without an explicit top-level operating split
Current major domains under the effective root:
- `docs/`
- `references/`
- `scripts/`
- `tests/`
- `lore/`
- `tables/`
- `assets/`

These are all valid surfaces, but they are presented side-by-side without a first-class “mode” split (Development mode vs Runtime mode).

### 3) Runtime workflow exists but is not the primary nav model
Canonical runtime documents are already strong:
- `docs/workflows/turn-loop.md`
- `docs/workflows/play-runbook.md`
- `docs/scripts/index.md`

However, these are not currently surfaced through a dual-mode architecture that makes it obvious which path to follow first.

### 4) Discoverability and link graph weakness
Inventory evidence shows:
- low internal markdown linkage
- many orphan markdown files
- broken links concentrated in the docs hub pathing

This means content quality is higher than navigability quality.

---

## Target Architecture (New Layout)

## Design principle
The repository will be organized around two operating lanes:

1. **Runtime Lane** (playing the game safely and consistently)
2. **Development Lane** (editing rules/docs/scripts/tests and shipping changes)

All other domains (`references`, `lore`, `tables`, `assets`) remain authoritative domain repositories, but are linked through these lanes.

### A) Root entry architecture
- `README.md` (new, root-level)
  - “Run the game” → runtime lane entrypoint
  - “Develop/edit the game” → development lane entrypoint
  - AGENTS scope overview for contributors

### B) Documentation architecture
- `runtime/docs/index.md` is a slim router to:
  - `runtime/docs/runtime/index.md` (runtime lane)
  - `development/index.md` (development lane, repo root)

#### Runtime lane (`runtime/docs/runtime/`)
- `index.md`
- turn-loop and play-runbook in `runtime/docs/workflows/`
- `script-usage-map.md` (mapping runtime-safe commands to turn-loop stages)
- `starting-campaign-guide.md`

#### Development lane (`development/` at repo root)
- `index.md` (this file's parent)
- `repo-structure-breakdown.md` (this file)
- `repo-maintenance-policy.md`
- quality/security/design-docs/appendices/ongoing-plans beneath development

### C) Domain architecture (retain, but hard-index and annotate)
- `references/`: mechanics canon, indexed by runtime-criticality
- `lore/`: world canon, with explicit runtime trigger usage guidance
- `tables/`: structured data tables with script consumer mapping
- `assets/`: templates/artifacts with usage moments and generation source
- `scripts/`: implementation and command modules; runtime safety metadata remains canonical in docs script registry
- `tests/`: test suites, grouped by purpose with an index and execution entrypoints

### D) Outlier normalization
- `archives/classes-v45.md` is an architecture outlier and should be relocated to a deterministic development appendix path and cross-linked to canonical class references.

---

## Step-by-Step Execution Order (Implementation Sequence)

1. **Create dual-mode entrypoints** (`README.md`, runtime START-HERE, development START-HERE).
2. **Stabilize canonical hubs** (`docs/index.md` as router + link repair).
3. **Move development-only docs** under `development/*`.
4. **Create/refresh domain READMEs** for `references`, `lore`, `tables`, `assets`, `scripts`, `tests`.
5. **Apply file placement matrix actions** (keep/move/merge/deprecate).
6. **Relink all hubs to ensure reachability** (no important orphan docs).
7. **Add structural validation checks** (link integrity and required-hub checks).
8. **Close with maintenance policy** to prevent architectural regression.

## Definition of “Fully Organized”
- A new contributor can choose Run vs Develop from root in <30 seconds.
- Every important doc is reachable from at least one canonical hub.
- Runtime workflow pages directly link required references and scripts.
- Development docs are grouped under a clearly defined development lane.
- Outliers and duplicate/legacy docs are merged, moved, or deprecated with explicit pointers.
