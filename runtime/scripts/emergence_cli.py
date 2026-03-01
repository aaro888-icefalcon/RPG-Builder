#!/usr/bin/env python3
"""
RPG ENGINE — Unified CLI Skeleton
Single entry point for all game mechanics. Outputs JSON for artifact population.

Usage:
    python emergence_cli.py <command> [options]

Commands:
    (none registered — populate with your game's mechanics)

To add a new command:
    1. Create a domain script in phases/3-resolution/skills/<domain>/scripts/
    2. Add a cmd_<name> function below that imports from it
    3. Register a subparser in main()
    4. Add the command to the dispatch dict
"""

import argparse
import json
import sys
import os
import random

# Ensure script directory is in path for imports
_script_dir = os.path.dirname(os.path.abspath(__file__))
if _script_dir not in sys.path:
    sys.path.insert(0, _script_dir)

# Parent directory (runtime/)
_parent_dir = os.path.dirname(_script_dir)
if _parent_dir not in sys.path:
    sys.path.insert(0, _parent_dir)

# Phase 3 domain script and table directories (physical co-location)
# Automatically adds any domain scripts/tables dirs that exist
_skills_dir = os.path.join(_parent_dir, 'phases', '3-resolution', 'skills')
if os.path.isdir(_skills_dir):
    for _domain in os.listdir(_skills_dir):
        for _subdir in ['scripts', 'tables']:
            _p = os.path.join(_skills_dir, _domain, _subdir)
            if os.path.isdir(_p) and _p not in sys.path:
                sys.path.insert(0, _p)


# ═══════════════════════════════════════════════════════════════════════════════
# COMMAND HANDLERS
# Add your game's command handlers here. Each should:
#   1. Import from a domain script
#   2. Call the domain function with parsed args
#   3. Print JSON output via json.dumps()
# ═══════════════════════════════════════════════════════════════════════════════

# Example:
# def cmd_roll(args):
#     """Roll dice."""
#     from dice import roll_2d6
#     result = roll_2d6(modifier=args.modifier)
#     print(json.dumps(result, indent=2, default=str))


def main():
    parser = argparse.ArgumentParser(
        description="RPG Engine — Unified CLI",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__
    )
    parser.add_argument(
        "--seed",
        type=int,
        help="Set RNG seed for reproducible command output"
    )

    subparsers = parser.add_subparsers(dest="command", help="Command to run")

    # ═══════════════════════════════════════════════════════════════════════════
    # SUBPARSER REGISTRATION
    # Add your game's subparsers here. Example:
    #
    # p_roll = subparsers.add_parser("roll", help="Roll dice")
    # p_roll.add_argument("--modifier", type=int, default=0)
    # ═══════════════════════════════════════════════════════════════════════════

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        sys.exit(1)

    if args.seed is not None:
        random.seed(args.seed)

    # ═══════════════════════════════════════════════════════════════════════════
    # COMMAND DISPATCH
    # Map command names to handler functions. Example:
    #   "roll": cmd_roll,
    # ═══════════════════════════════════════════════════════════════════════════
    commands = {
    }

    if args.command not in commands:
        print(json.dumps({
            "error": True,
            "message": f"Unknown command: {args.command}. No game commands registered yet."
        }, indent=2), file=sys.stderr)
        sys.exit(1)

    try:
        commands[args.command](args)
    except Exception as e:
        error_output = {
            "error": True,
            "command": args.command,
            "message": str(e),
            "type": type(e).__name__
        }
        print(json.dumps(error_output, indent=2), file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
