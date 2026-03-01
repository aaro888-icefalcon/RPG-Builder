#!/bin/bash
# =============================================================================
# EMERGENCE RPG — Stop Hook: Combat Round Lifecycle Validator
# =============================================================================
# Enforces that turn-start and round-end CLI commands are executed during
# combat when conditions are active. Prevents condition auto-damage and
# ticking from being forgotten.
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
HAS_CONDITIONS=false
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

        # Check if any entity has conditions
        CONDITION_COUNT=$(cat "$STATE_FILE" | jq '[.current_scene.combat_state.entities[]?.conditions // [] | length] | add // 0' 2>/dev/null)
        # Also check PC conditions
        PC_CONDITIONS=$(cat "$STATE_FILE" | jq '.character.conditions // [] | length' 2>/dev/null)
        TOTAL_CONDITIONS=$(( ${CONDITION_COUNT:-0} + ${PC_CONDITIONS:-0} ))

        if [ "$TOTAL_CONDITIONS" -gt 0 ]; then
            HAS_CONDITIONS=true
        fi
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

# ---- Skip if combat ended this turn ----
if echo "$LAST_ASSISTANT" | grep -qiE "combat (ends|over|concluded)|the fight is over|enemies (are|lie) (dead|defeated|down)|you.*(win|survive|prevail).*combat"; then
    exit 0
fi

VIOLATIONS=""
RECENT_TRANSCRIPT=$(tail -80 "$TRANSCRIPT_PATH" 2>/dev/null)

# ---- Check turn-start if conditions exist ----
if [ "$HAS_CONDITIONS" = true ]; then
    # Check if a combat turn was narrated (either player or enemy)
    TURN_NARRATED=false
    if echo "$LAST_ASSISTANT" | grep -qiE "Round [0-9]|'s Turn|What do you do\?|🐺|Action:.*→"; then
        TURN_NARRATED=true
    fi

    if [ "$TURN_NARRATED" = true ]; then
        TURN_START_CALLED=$(echo "$RECENT_TRANSCRIPT" | grep -c "turn-start" || echo "0")
        if [ "$TURN_START_CALLED" = "0" ]; then
            VIOLATIONS="${VIOLATIONS}COMBAT TURN WITHOUT turn-start CLI: Active conditions exist but turn-start was not run. Conditions must tick: auto-damage, penalties, duration decrements.\nRequired: cd \"$CLAUDE_PROJECT_DIR\"/runtime/scripts && python3 emergence_cli.py turn-start --entity-json '...'\nSee runtime/phases/3-resolution/skills/combat/turn-start.md.\n\n"
        fi
    fi
fi

# ---- Check round-end if round transition detected ----
if echo "$LAST_ASSISTANT" | grep -qiE "🔄.*Round [0-9]+ End|Round [0-9]+ (ends|complete|over)"; then
    ROUND_END_CALLED=$(echo "$RECENT_TRANSCRIPT" | grep -c "round-end" || echo "0")
    if [ "$ROUND_END_CALLED" = "0" ]; then
        VIOLATIONS="${VIOLATIONS}ROUND END WITHOUT round-end CLI: Round transition detected but round-end was not run. Conditions must tick at round boundaries.\nRequired: cd \"$CLAUDE_PROJECT_DIR\"/runtime/scripts && python3 emergence_cli.py round-end --combat-json '...' --entities-json '[...]'\nSee runtime/phases/3-resolution/skills/combat/round-end.md.\n\n"
    fi
fi

if [ -n "$VIOLATIONS" ]; then
    REASON=$(printf "COMBAT ROUND LIFECYCLE VIOLATION\n\n%b" "$VIOLATIONS")
    echo "{\"decision\": \"block\", \"reason\": $(echo "$REASON" | jq -Rs .)}"
    exit 0
fi

exit 0
