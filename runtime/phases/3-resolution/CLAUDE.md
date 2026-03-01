# Phase 3 — Mechanical Resolution

Execute CLI commands to adjudicate player actions. All mechanics run through emergence_cli.py.

## When This Phase Runs
- After action interpretation (Phase 2) has selected the CLI command
- This is the ONLY phase where CLI scripts execute

## Mandatory Steps
1. Execute the selected emergence_cli.py subcommand with correct arguments
2. Parse JSON output — treat as canonical mechanical truth
3. Never hand-calculate or override CLI results
4. Record RNG seed used

## Domain Structure

Phase 3 organizes mechanics into domain sub-groups. Create domains as needed:

```
skills/
  <domain-name>/
    index.md          — Domain content inventory
    <skill>.md        — Skill instruction files
    scripts/          — Python domain logic
    tables/           — Data tables
    references/       — Domain reference docs
```

## Key Rule
NEVER substitute hand-rolled mechanics for CLI output. If a script fails, halt the turn.
