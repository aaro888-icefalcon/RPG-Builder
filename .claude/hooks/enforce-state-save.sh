#!/bin/bash
# =============================================================================
# EMERGENCE RPG — Stop Hook: Enforce State Save Every Turn
# =============================================================================
# Blocks if state.json was not written/updated during this turn.
# Every GM turn must end with a state.json write — even if just updating
# world.current_time and current_scene. State is the single source of truth.
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

# ---- Check if we're in an active RPG session ----
IN_RPG_SESSION=false
TAIL_CONTENT=$(tail -30 "$TRANSCRIPT_PATH" 2>/dev/null || echo "")
if echo "$TAIL_CONTENT" | grep -qi "emergence\|what do you do\|emergence_cli\|state\.json\|world pulse\|clock-tick\|combat.*round\|HP:.*Stamina\|Vaelithar"; then
    IN_RPG_SESSION=true
fi

if [ "$IN_RPG_SESSION" = false ]; then
    exit 0
fi

# ---- Check for session setup exceptions ----
# During session zero, character creation, campaign selection — state may not exist yet
LAST_ASSISTANT=$(tac "$TRANSCRIPT_PATH" 2>/dev/null | while IFS= read -r line; do
    ROLE=$(echo "$line" | jq -r '.role // empty' 2>/dev/null)
    if [ "$ROLE" = "assistant" ]; then
        echo "$line" | jq -r '.content // empty' 2>/dev/null
        break
    fi
done)

if echo "$LAST_ASSISTANT" | grep -qiE "campaign name|session zero|choose.*aspect|choose.*archetype|select.*form|which campaign|character concept|what.*class|new campaign"; then
    exit 0
fi

# ---- Check if state.json was written this turn ----
# Look for Write or Edit tool calls targeting state.json in recent transcript entries
# We check the last 80 lines to cover a full turn with multiple tool calls
STATE_WRITTEN=$(tail -80 "$TRANSCRIPT_PATH" 2>/dev/null | grep -c "state\.json" || echo "0")

# More specifically, look for tool_use entries that wrote to state.json
STATE_WRITE_TOOL=$(tail -80 "$TRANSCRIPT_PATH" 2>/dev/null | while IFS= read -r line; do
    # Check for Write/Edit tool calls with state.json in the path
    if echo "$line" | jq -r '.content // empty' 2>/dev/null | grep -q "state\.json"; then
        TOOL=$(echo "$line" | jq -r '.tool_name // empty' 2>/dev/null)
        if [ "$TOOL" = "Write" ] || [ "$TOOL" = "Edit" ]; then
            echo "FOUND"
            break
        fi
    fi
    # Also check tool_input for file_path containing state.json
    if echo "$line" | jq -r '.tool_input.file_path // empty' 2>/dev/null | grep -q "state\.json"; then
        echo "FOUND"
        break
    fi
done)

if [ "$STATE_WRITE_TOOL" = "FOUND" ] || [ "$STATE_WRITTEN" -gt 1 ]; then
    exit 0
fi

# ---- Find campaign state path for the error message ----
STATE_FILE=""
if [ -d "$PROJECT_DIR/campaigns" ]; then
    STATE_FILE=$(find "$PROJECT_DIR/campaigns" -name "state.json" -maxdepth 2 2>/dev/null | head -1)
fi
if [ -z "$STATE_FILE" ] && [ -d "$PROJECT_DIR/runtime/campaigns" ]; then
    STATE_FILE=$(find "$PROJECT_DIR/runtime/campaigns" -name "state.json" -maxdepth 2 2>/dev/null | head -1)
fi

if [ -z "$STATE_FILE" ]; then
    # No state file exists yet — probably pre-session-zero
    exit 0
fi

# ---- Block: state not saved ----
REASON="STATE NOT SAVED: You did not update state.json this turn. You MUST write state.json EVERY turn — it is the single source of truth. Update at minimum: world.current_time, current_scene, and meta.last_played. If combat occurred, HP/resources must reflect current values. If clocks ticked, update clock values. See runtime/phases/5-persistence/skills/state-persistence.md. Write to: $STATE_FILE"

echo "{\"decision\": \"block\", \"reason\": $(echo "$REASON" | jq -Rs .)}"
exit 0
