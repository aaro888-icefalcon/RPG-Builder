# Tests — Validation Suite

Scope: `runtime/tests/`

## Operating Rules

- Prefer targeted tests first, then broader suites.
- Record exact commands and outcomes.
- If tests rely on generated state/data, reset fixtures between runs.
- Treat failures as signal — do not change expected outputs without cause.

## How to Run

- Core tests: `python runtime/tests/run_all_tests.py 1`
- Extended:   `python runtime/tests/run_all_tests.py 2`
- Full:       `python runtime/tests/run_all_tests.py`
