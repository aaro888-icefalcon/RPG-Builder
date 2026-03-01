# Phase Manifest

Machine-readable mapping of the 6-phase GM pipeline.

## PHASE 1: CONTEXT_LOADING
- directory: 1-context-loading/
- cli_commands: (none — this phase reads state and lore files)
- references: (none — populate with your game's references)
- lore: (none — populate with your game's lore)

## PHASE 2: ACTION_INTERPRETATION
- directory: 2-action-interpretation/
- cli_commands: (none — populate with your game's master router)
- references: (none — populate with CLI reference)

## PHASE 3: MECHANICAL_RESOLUTION
- directory: 3-resolution/
- domains: (none — create domain sub-groups for your game)

## PHASE 4: NARRATIVE_TRANSLATION
- directory: 4-narrative/
- references: (none — populate with narration guides)
- assets: (none — populate with display templates)

## PHASE 5: STATE_PERSISTENCE
- directory: 5-persistence/
- cli_commands: validate-state (post-write check)
- references: schemas/state.schema.json (state shape contract)

## PHASE 6: VALIDATION
- directory: 6-validation/
- cli_commands: validate-state, validate-reference-freshness
