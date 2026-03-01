# Phase 2 — Action Interpretation

Classify the player's declared action and select the appropriate CLI command.

## When This Phase Runs
- After context loading, when player declares an action
- Before any CLI execution

## Mandatory Steps
1. Check for `DEVELOPMENT:` prefix — if present, skip to development mode
2. Run the master router (action classifier) with player message + scene context
3. Read turn type and required CLI commands from output
4. Determine required arguments
5. DO NOT execute yet — that's Phase 3

## Content To Create

Populate this phase with your game's action interpretation content:

- **`references/`** — CLI command reference documentation
- **`skills/`** — Action classification, CLI selection procedures
