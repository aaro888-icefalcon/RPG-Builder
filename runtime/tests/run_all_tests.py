"""
RPG Engine — Test Runner
Discovers and runs all test scripts, outputs summary.
"""

import sys
import os
import importlib
import time

# Ensure we can find our test modules
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'scripts'))

# Phase 3 domain script and table directories (physical co-location)
_runtime_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
_skills_dir = os.path.join(_runtime_dir, 'phases', '3-resolution', 'skills')
if os.path.isdir(_skills_dir):
    for _domain in os.listdir(_skills_dir):
        for _subdir in ['scripts', 'tables']:
            _p = os.path.join(_skills_dir, _domain, _subdir)
            if os.path.isdir(_p) and _p not in sys.path:
                sys.path.insert(0, _p)

# Core test modules (always run)
TEST_MODULES = [
    ("S1: State Schema Validation", "test_state_schema"),
]

# Optional game-specific tests (only run if they exist)
OPTIONAL_MODULES = [
    # Add your game's test modules here. Example:
    # ("Balance: Hit Rates", "balance_test_a1"),
]


def run_all(phase=None):
    """
    Run all tests. Optional phase filter:
    - None or 0: run all available
    - 1: run core only
    - 2+: run core + available optional tests
    """
    print("=" * 70)
    print("RPG ENGINE — TEST SUITE")
    print("=" * 70)

    modules_to_run = list(TEST_MODULES)

    if phase is None or phase >= 2:
        for name, mod_name in OPTIONAL_MODULES:
            try:
                importlib.import_module(mod_name)
                modules_to_run.append((name, mod_name))
            except ImportError:
                pass

    summary = []
    total_passed = 0
    total_failed = 0
    total_time = 0

    for test_name, mod_name in modules_to_run:
        print(f"\n{'---' * 23}")
        try:
            mod = importlib.import_module(mod_name)
            start = time.time()
            passed = mod.run_test()
            elapsed = time.time() - start
            total_time += elapsed

            if passed:
                total_passed += 1
                summary.append(f"  [PASS] {test_name} ({elapsed:.1f}s)")
            else:
                total_failed += 1
                summary.append(f"  [FAIL] {test_name} ({elapsed:.1f}s)")
        except Exception as e:
            total_failed += 1
            summary.append(f"  [ERR]  {test_name}: {e}")

    print(f"\n{'=' * 70}")
    print("SUMMARY")
    print(f"{'=' * 70}")
    for s in summary:
        print(s)
    print(f"\nTotal: {total_passed} passed, {total_failed} failed ({total_time:.1f}s)")
    print(f"{'=' * 70}")

    return total_failed == 0


if __name__ == "__main__":
    phase = None
    if len(sys.argv) > 1:
        try:
            phase = int(sys.argv[1])
        except ValueError:
            pass

    success = run_all(phase)
    sys.exit(0 if success else 1)
