# CI Local Command Equivalents

Run from repository root:

```bash
cd "runtime"
```

## smoke-balance

```bash
python tests/run_all_tests.py 1
```

## state-validators

```bash
python scripts/validate_reference_freshness.py
python scripts/validate_docs_structure.py
```

## regen-check

```bash
python scripts/validate_reference_freshness.py
python scripts/validate_docs_structure.py
git update-index -q --refresh
git diff --exit-code -- .
```

If the final `git diff` command exits non-zero, regenerate and commit the derived artifacts before pushing.
