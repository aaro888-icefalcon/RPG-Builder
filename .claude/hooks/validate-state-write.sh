#!/bin/bash
# =============================================================================
# EMERGENCE RPG — PreToolUse Hook: State Write Validator
# =============================================================================
# Runs before Write/Edit tool calls. If the target is a state.json file,
# validates that the write doesn't contain obvious inconsistencies.
#
# Hook event: PreToolUse (matcher: Write|Edit)
# Exit 0 = allow
# Exit 2 + stderr = block with reason
# =============================================================================

INPUT=$(cat)

# Get the file path being written
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
if [ -z "$FILE_PATH" ]; then
    exit 0
fi

# Only validate state.json files
if ! echo "$FILE_PATH" | grep -q "state\.json"; then
    exit 0
fi

# For Write tool, check the content
CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // empty' 2>/dev/null)
if [ -z "$CONTENT" ]; then
    # Might be an Edit tool call — allow those through (they're partial updates)
    exit 0
fi

# ---- Validate the state.json content ----
ERRORS=""

# Check it's valid JSON
if ! echo "$CONTENT" | jq '.' > /dev/null 2>&1; then
    echo "BLOCKED: state.json content is not valid JSON. Fix the JSON syntax before writing." >&2
    exit 2
fi

# Check required top-level keys exist
HAS_CHARACTER=$(echo "$CONTENT" | jq 'has("character")' 2>/dev/null)
HAS_WORLD=$(echo "$CONTENT" | jq 'has("world")' 2>/dev/null)
HAS_META=$(echo "$CONTENT" | jq 'has("meta")' 2>/dev/null)

if [ "$HAS_CHARACTER" != "true" ]; then
    ERRORS="${ERRORS}Missing 'character' key. "
fi
if [ "$HAS_WORLD" != "true" ]; then
    ERRORS="${ERRORS}Missing 'world' key. "
fi
if [ "$HAS_META" != "true" ]; then
    ERRORS="${ERRORS}Missing 'meta' key. "
fi

# Check HP doesn't exceed max
HP_CUR=$(echo "$CONTENT" | jq -r '.character.hp.current // 0' 2>/dev/null)
HP_MAX=$(echo "$CONTENT" | jq -r '.character.hp.max // 0' 2>/dev/null)
if [ "$HP_CUR" -gt "$HP_MAX" ] 2>/dev/null; then
    ERRORS="${ERRORS}HP current ($HP_CUR) exceeds max ($HP_MAX). "
fi

# Check HP isn't negative (should be 0 minimum)
if [ "$HP_CUR" -lt 0 ] 2>/dev/null; then
    ERRORS="${ERRORS}HP current ($HP_CUR) is negative — minimum is 0. "
fi

# Check Stamina doesn't exceed max
STAM_CUR=$(echo "$CONTENT" | jq -r '.character.stamina.current // 0' 2>/dev/null)
STAM_MAX=$(echo "$CONTENT" | jq -r '.character.stamina.max // 0' 2>/dev/null)
if [ "$STAM_CUR" -gt "$STAM_MAX" ] 2>/dev/null; then
    ERRORS="${ERRORS}Stamina current ($STAM_CUR) exceeds max ($STAM_MAX). "
fi

# Check Mana doesn't exceed max
MANA_CUR=$(echo "$CONTENT" | jq -r '.character.mana.current // 0' 2>/dev/null)
MANA_MAX=$(echo "$CONTENT" | jq -r '.character.mana.max // 0' 2>/dev/null)
if [ "$MANA_CUR" -gt "$MANA_MAX" ] 2>/dev/null; then
    ERRORS="${ERRORS}Mana current ($MANA_CUR) exceeds max ($MANA_MAX). "
fi

# Check Composure doesn't exceed max
COMP_CUR=$(echo "$CONTENT" | jq -r '.character.composure.current // 0' 2>/dev/null)
COMP_MAX=$(echo "$CONTENT" | jq -r '.character.composure.max // 0' 2>/dev/null)
if [ "$COMP_CUR" -gt "$COMP_MAX" ] 2>/dev/null; then
    ERRORS="${ERRORS}Composure current ($COMP_CUR) exceeds max ($COMP_MAX). "
fi

# Check Entropy is in range (0-100)
ENTROPY=$(echo "$CONTENT" | jq -r '.world.entropy // 50' 2>/dev/null)
if [ "$ENTROPY" -gt 100 ] 2>/dev/null; then
    ERRORS="${ERRORS}Entropy ($ENTROPY) exceeds maximum of 100. "
fi
if [ "$ENTROPY" -lt 0 ] 2>/dev/null; then
    ERRORS="${ERRORS}Entropy ($ENTROPY) is negative — minimum is 0. "
fi

# Check current_scene key exists
HAS_SCENE=$(echo "$CONTENT" | jq 'has("current_scene")' 2>/dev/null)
if [ "$HAS_SCENE" != "true" ]; then
    ERRORS="${ERRORS}Missing 'current_scene' key — every state must track the current scene. "
fi

# Check meta.last_played exists and is being updated
HAS_LAST_PLAYED=$(echo "$CONTENT" | jq -r '.meta.last_played // empty' 2>/dev/null)
if [ -z "$HAS_LAST_PLAYED" ]; then
    ERRORS="${ERRORS}Missing 'meta.last_played' — update this timestamp every save. "
fi

# Check clock values don't exceed max
CLOCK_ERRORS=$(echo "$CONTENT" | jq -r '
    [
        (.world.human_factions[]? | .clock | select(.current > .max) | "Clock \(.name): current \(.current) > max \(.max)"),
        (.world.meta_clocks[]? | select(.current > .max) | "Clock \(.name): current \(.current) > max \(.max)")
    ] | .[]
' 2>/dev/null)

if [ -n "$CLOCK_ERRORS" ]; then
    ERRORS="${ERRORS}Clock overflow: $CLOCK_ERRORS. "
fi

# Check level is reasonable (0-30)
LEVEL=$(echo "$CONTENT" | jq -r '.character.level // 0' 2>/dev/null)
if [ "$LEVEL" -gt 30 ] 2>/dev/null; then
    ERRORS="${ERRORS}Level ($LEVEL) exceeds maximum of 30. "
fi

# ---- Report errors ----
if [ -n "$ERRORS" ]; then
    echo "BLOCKED: state.json validation failed: $ERRORS Fix these issues before saving." >&2
    exit 2
fi

# All checks passed
exit 0
