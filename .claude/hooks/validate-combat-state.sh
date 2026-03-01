#!/bin/bash
# =============================================================================
# EMERGENCE RPG — Stop Hook: Combat Display Format Validator
# =============================================================================
# When combat is active, enforces the MANDATORY combat display format
# from runtime/CLAUDE.md §3 — Combat Display Format. Every combat turn
# must include resource bars, enemy table, available actions with AP costs,
# and "What do you do?"
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

# ---- Detect if we're in combat ----
# AUTHORITATIVE CHECK: state.json combat_state is the single source of truth
# If combat_state is null, we are NOT in combat regardless of recent transcript content

IN_COMBAT=false

# Find state.json - this is the authoritative source
STATE_FILE=""
if [ -d "$PROJECT_DIR/campaigns" ]; then
    STATE_FILE=$(find "$PROJECT_DIR/campaigns" -name "state.json" -maxdepth 2 2>/dev/null | head -1)
fi
if [ -z "$STATE_FILE" ] && [ -d "$PROJECT_DIR/runtime/campaigns" ]; then
    STATE_FILE=$(find "$PROJECT_DIR/runtime/campaigns" -name "state.json" -maxdepth 2 2>/dev/null | head -1)
fi

# Primary check: state.json combat_state
if [ -n "$STATE_FILE" ] && [ -f "$STATE_FILE" ]; then
    COMBAT_ACTIVE=$(cat "$STATE_FILE" | jq -r '.current_scene.combat_state.active // false' 2>/dev/null)
    if [ "$COMBAT_ACTIVE" = "true" ]; then
        IN_COMBAT=true
    fi
fi

# If state.json says no combat, trust it and exit
if [ "$IN_COMBAT" = false ]; then
    exit 0
fi

# Get last assistant message for format checking
LAST_ASSISTANT=$(tac "$TRANSCRIPT_PATH" 2>/dev/null | while IFS= read -r line; do
    ROLE=$(echo "$line" | jq -r '.role // empty' 2>/dev/null)
    if [ "$ROLE" = "assistant" ]; then
        echo "$line" | jq -r '.content // empty' 2>/dev/null
        break
    fi
done)

# ---- If combat ended this turn, skip validation ----
if echo "$LAST_ASSISTANT" | grep -qiE "combat (ends|over|concluded)|the fight is over|enemies (are|lie) (dead|defeated|down)|you.*(win|survive|prevail).*combat"; then
    exit 0
fi

# ---- Validate combat display format ----
MISSING=""

# Check for resource display line (HP/Stamina)
if ! echo "$LAST_ASSISTANT" | grep -qE "\*\*HP:\*\*.*[0-9]+/[0-9]+"; then
    MISSING="${MISSING}- Missing HP display (must show **HP:** X/X)\n"
fi

if ! echo "$LAST_ASSISTANT" | grep -qiE "\*\*Stamina:\*\*.*[0-9]+/[0-9]+"; then
    MISSING="${MISSING}- Missing Stamina display (must show **Stamina:** X/X)\n"
fi

# Check for stance/AP line
if ! echo "$LAST_ASSISTANT" | grep -qiE "\*\*Stance:\*\*|\*\*AP:\*\*.*[0-9]+/[0-9]+"; then
    MISSING="${MISSING}- Missing Stance/AP display (must show **Stance:** [Name] | **AP:** X/X)\n"
fi

# Check for RP (Reaction Points) display
if ! echo "$LAST_ASSISTANT" | grep -qiE "\*\*RP:\*\*.*[0-9]+/[0-9]+"; then
    MISSING="${MISSING}- Missing RP display (must show **RP:** X/X for Reaction Points)\n"
fi

# Check for enemies table
if ! echo "$LAST_ASSISTANT" | grep -qE "\| .*(HP|DEF|ATK|DMG).* \|"; then
    MISSING="${MISSING}- Missing Enemies table (must show | Name | HP | DEF | ... |)\n"
fi

# Check for available actions
if ! echo "$LAST_ASSISTANT" | grep -qiE "available actions|action.*\|.*ap.*\|"; then
    MISSING="${MISSING}- Missing Available Actions table (must list actions with AP costs)\n"
fi

# Check for "What do you do?"
if ! echo "$LAST_ASSISTANT" | grep -qi "what do you do"; then
    MISSING="${MISSING}- Missing 'What do you do?' prompt at end\n"
fi

if [ -n "$MISSING" ]; then
    REASON=$(printf "COMBAT DISPLAY FORMAT VIOLATION: You are in combat but your response is missing required elements:\n\n%b\nThe mandatory combat format (see runtime/phases/3-resolution/skills/combat/player-turn.md) requires:\n## Combat — Round X | [Name]'s Turn\n**HP:** X/X (State) | **Stamina:** X/X | **Composure:** X/X (State)\n**Stance:** [Stance] | **DEF:** X | **AP:** X/X | **RP:** X/X\n### Enemies table\n### Available Actions with AP costs and technique tags\n### Reactions (Parry/Dodge/Intercept/OA)\n**What do you do?**\n\nFix your response to include ALL missing elements." "$MISSING")

    echo "{\"decision\": \"block\", \"reason\": $(echo "$REASON" | jq -Rs .)}"
    exit 0
fi

exit 0
