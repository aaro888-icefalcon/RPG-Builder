#!/bin/bash
# =============================================================================
# EMERGENCE RPG — Stop Hook: Enemy Behavior Evaluator Enforcement
# =============================================================================
# When combat is active and an enemy turn was narrated, enforces that the
# `evaluate-behavior` CLI was called. Prevents AI from choosing "softer"
# enemy actions instead of using the deterministic behavior evaluator.
#
# Hook event: Stop
# =============================================================================

INPUT=$(cat)

STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
    exit 0
fi

TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty')
if [ -z "$TRANSCRIPT_PATH" ] || [ ! -f "$TRANSCRIPT_PATH" ]; then
    exit 0
fi

PROJECT_DIR=$(echo "$INPUT" | jq -r '.cwd // empty')
if [ -z "$PROJECT_DIR" ]; then
    exit 0
fi

# ---- Check if we're in combat via state.json ----
IN_COMBAT=false
STATE_FILE=""
if [ -d "$PROJECT_DIR/campaigns" ]; then
    STATE_FILE=$(find "$PROJECT_DIR/campaigns" -name "state.json" -maxdepth 2 2>/dev/null | head -1)
fi
if [ -z "$STATE_FILE" ] && [ -d "$PROJECT_DIR/runtime/campaigns" ]; then
    STATE_FILE=$(find "$PROJECT_DIR/runtime/campaigns" -name "state.json" -maxdepth 2 2>/dev/null | head -1)
fi

if [ -n "$STATE_FILE" ] && [ -f "$STATE_FILE" ]; then
    COMBAT_ACTIVE=$(cat "$STATE_FILE" | jq -r '.current_scene.combat_state.active // false' 2>/dev/null)
    if [ "$COMBAT_ACTIVE" = "true" ]; then
        IN_COMBAT=true
    fi
fi

if [ "$IN_COMBAT" = false ]; then
    exit 0
fi

# ---- Get last assistant message ----
LAST_ASSISTANT=$(tac "$TRANSCRIPT_PATH" 2>/dev/null | while IFS= read -r line; do
    ROLE=$(echo "$line" | jq -r '.role // empty' 2>/dev/null)
    if [ "$ROLE" = "assistant" ]; then
        echo "$line" | jq -r '.content // empty' 2>/dev/null
        break
    fi
done)

# ---- Check if combat ended this turn ----
if echo "$LAST_ASSISTANT" | grep -qiE "combat (ends|over|concluded)|the fight is over|enemies (are|lie) (dead|defeated|down)|you.*(win|survive|prevail).*combat"; then
    exit 0
fi

# ---- Check if an enemy turn was narrated ----
# Look for Enemy Action Block patterns
ENEMY_TURN_NARRATED=false
if echo "$LAST_ASSISTANT" | grep -qE "🐺.*'s Turn|Enemy.*Turn|Action:.*→.*Roll:"; then
    ENEMY_TURN_NARRATED=true
fi
# Also check for enemy attack narration without the formal block
if echo "$LAST_ASSISTANT" | grep -qiE "(the|a) .*(wolf|creature|beast|goblin|bandit|enemy|spider|horror|thing|warrior|soldier|guard|raider|cultist).*(attacks?|strikes?|slashes?|lunges?|bites?|claws?|swings?|charges?|fires?|shoots?|casts?) "; then
    ENEMY_TURN_NARRATED=true
fi

if [ "$ENEMY_TURN_NARRATED" = false ]; then
    exit 0
fi

# ---- Check if evaluate-behavior CLI was called this turn ----
BEHAVIOR_CALLED=$(tail -80 "$TRANSCRIPT_PATH" 2>/dev/null | grep -c "evaluate-behavior" || echo "0")

if [ "$BEHAVIOR_CALLED" = "0" ]; then
    REASON=$(printf "ENEMY TURN WITHOUT BEHAVIOR EVALUATION\n\nYou narrated an enemy action without running the evaluate-behavior CLI.\nEnemy actions must be deterministic — run the evaluator first.\n\nRequired:\ncd \"\$CLAUDE_PROJECT_DIR\"/runtime/scripts && python3 emergence_cli.py evaluate-behavior --entity-json '...' --combat-json '...'\n\nThen narrate the RETURNED action. Do not choose a different action.\nSee runtime/phases/3-resolution/skills/combat/enemy-turn.md.")

    echo "{\"decision\": \"block\", \"reason\": $(echo "$REASON" | jq -Rs .)}"
    exit 0
fi

exit 0
