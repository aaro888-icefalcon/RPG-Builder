# Tests Index

Validation and regression suites for state schema and game mechanics.

## What belongs here
- State validation tests, balance tests, stress tests, integration checks, and fixtures.

## What does not belong here
- Runtime turn operations.
- Canonical content rules.

## Current Tests

| File | Purpose |
|---|---|
| `run_all_tests.py` | Test runner (phase-based suite) |
| `test_state_schema.py` | State schema validation (35 checks) |

## Usage
- Development/CI only (not runtime turn commands).

## Related guidance
- Quality commands: `../../development/quality/ci-commands.md`
