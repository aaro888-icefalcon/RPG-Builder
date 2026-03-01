#!/bin/bash
# =============================================================================
# EMERGENCE RPG — Stop Hook: Forced Consequence Validator
# =============================================================================
# When the `move` CLI returns a forced consequence, warns if the narrative
# may not reference it. v5.0 forced consequences are BINDING — no substitution.
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

# ---- Check if move CLI was ACTUALLY EXECUTED this turn ----
# Must match actual Bash command execution, not text mentions in conversation.
# Require "python" prefix + "emergence_cli.py" + " move " (with space after, so it
# doesn't match "move" as part of "moves", "movement", "scene-pressure", etc.)
RECENT_LINES=$(tail -200 "$TRANSCRIPT_PATH" 2>/dev/null)

# Match only actual CLI invocations: "python[3] ... emergence_cli.py move --"
MOVE_OUTPUT=$(echo "$RECENT_LINES" | grep -E "python[3]?\s+.*emergence_cli\.py\s+move\s+" | head -5)

if [ -z "$MOVE_OUTPUT" ]; then
    exit 0
fi

# Now look for the JSON output that follows the move CLI execution.
# The move CLI outputs JSON with a "forced_move" key containing "move_id".
# Search for actual JSON output keys, not loose word patterns.
MOVE_JSON_OUTPUT=$(echo "$RECENT_LINES" | grep -A 50 "python.*emergence_cli\.py move " | grep -E '"forced_move"|"move_id"|"consequence"' | head -10)

if [ -z "$MOVE_JSON_OUTPUT" ]; then
    exit 0
fi

# Extract forced consequence type from actual JSON output fields
FORCED_CONSEQUENCE=""

if echo "$MOVE_JSON_OUTPUT" | grep -qE '"move_id".*"deal_damage"'; then
    FORCED_CONSEQUENCE="deal_damage"
elif echo "$MOVE_JSON_OUTPUT" | grep -qE '"move_id".*"tick_clock"'; then
    FORCED_CONSEQUENCE="tick_clock"
elif echo "$MOVE_JSON_OUTPUT" | grep -qE '"move_id".*"worsen_position"'; then
    FORCED_CONSEQUENCE="worsen_position"
elif echo "$MOVE_JSON_OUTPUT" | grep -qE '"move_id".*"separate"'; then
    FORCED_CONSEQUENCE="separate"
elif echo "$MOVE_JSON_OUTPUT" | grep -qE '"move_id".*"destroy_resource"'; then
    FORCED_CONSEQUENCE="destroy_resource"
elif echo "$MOVE_JSON_OUTPUT" | grep -qE '"move_id".*"capture"'; then
    FORCED_CONSEQUENCE="capture"
elif echo "$MOVE_JSON_OUTPUT" | grep -qE '"move_id".*"reveal_threat"'; then
    FORCED_CONSEQUENCE="reveal_threat"
elif echo "$MOVE_JSON_OUTPUT" | grep -qE '"move_id".*"use_up_resources"'; then
    FORCED_CONSEQUENCE="use_resources"
fi

# If no forced consequence detected, exit cleanly
if [ -z "$FORCED_CONSEQUENCE" ]; then
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

# ---- Check if narrative references the forced consequence ----
NARRATED=false

case "$FORCED_CONSEQUENCE" in
    "deal_damage")
        if echo "$LAST_ASSISTANT" | grep -qiE "damage|HP.*→|takes? [0-9]|wounds?|injur|hurt|bleed|pain|struck|hit"; then
            NARRATED=true
        fi
        ;;
    "tick_clock")
        if echo "$LAST_ASSISTANT" | grep -qiE "clock|⧗|advances?|progress|ticks?.*forward"; then
            NARRATED=true
        fi
        ;;
    "worsen_position")
        if echo "$LAST_ASSISTANT" | grep -qiE "position.*worsen|situation.*worse|desperate|cornered|disadvantage|ground.*lost|forced.*back"; then
            NARRATED=true
        fi
        ;;
    "separate")
        if echo "$LAST_ASSISTANT" | grep -qiE "separat|isolat|cut.*off|alone|split.*apart|divided"; then
            NARRATED=true
        fi
        ;;
    "destroy_resource")
        if echo "$LAST_ASSISTANT" | grep -qiE "destroy|broken|shatter|lost|ruined|damaged.*equipment|drops?.*item"; then
            NARRATED=true
        fi
        ;;
    "capture")
        if echo "$LAST_ASSISTANT" | grep -qiE "captur|trap|restrain|grab|pin|hold.*down|caught|ensnare"; then
            NARRATED=true
        fi
        ;;
    "reveal_threat")
        if echo "$LAST_ASSISTANT" | grep -qiE "reveal|notice|discover|emerge|appear|new.*threat|danger.*becomes"; then
            NARRATED=true
        fi
        ;;
    "use_resources")
        if echo "$LAST_ASSISTANT" | grep -qiE "use.*up|deplet|spent|consumed|lost.*supplies|exhaust"; then
            NARRATED=true
        fi
        ;;
esac

if [ "$NARRATED" = false ]; then
    REASON=$(printf "FORCED CONSEQUENCE MAY NOT BE NARRATED\n\nThe move CLI returned forced consequence: %s\nYour narrative may not reflect this. Verify you narrated this specific consequence.\n\nv5.0 rule: CLI-selected consequences are BINDING. No substitution.\nSee runtime/phases/3-resolution/skills/core/forced-consequence.md." "$FORCED_CONSEQUENCE")

    echo "{\"decision\": \"block\", \"reason\": $(echo "$REASON" | jq -Rs .)}"
    exit 0
fi

exit 0
