#!/bin/bash
# =============================================================================
# EMERGENCE RPG — UserPromptSubmit Hook: Lore Loading Enforcer
# =============================================================================
# Detects faction names, location keywords, creature references, and
# world-building questions in the player's message. Injects reminders
# to load the appropriate lore file BEFORE responding.
#
# Hook event: UserPromptSubmit
# Exit 0 + stdout = context added to Claude's processing
# =============================================================================

INPUT=$(cat)

PROJECT_DIR=$(echo "$INPUT" | jq -r '.cwd // empty')
if [ -z "$PROJECT_DIR" ]; then
    exit 0
fi

# ---- Find state.json to get faction names ----
STATE_FILE=""
if [ -d "$PROJECT_DIR/campaigns" ]; then
    STATE_FILE=$(find "$PROJECT_DIR/campaigns" -name "state.json" -maxdepth 2 2>/dev/null | head -1)
fi
if [ -z "$STATE_FILE" ] && [ -d "$PROJECT_DIR/runtime/campaigns" ]; then
    STATE_FILE=$(find "$PROJECT_DIR/runtime/campaigns" -name "state.json" -maxdepth 2 2>/dev/null | head -1)
fi

if [ -z "$STATE_FILE" ] || [ ! -f "$STATE_FILE" ]; then
    exit 0
fi

# ---- Get the user's message from transcript ----
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty')
if [ -z "$TRANSCRIPT_PATH" ] || [ ! -f "$TRANSCRIPT_PATH" ]; then
    exit 0
fi

LAST_USER=$(tac "$TRANSCRIPT_PATH" 2>/dev/null | while IFS= read -r line; do
    ROLE=$(echo "$line" | jq -r '.role // empty' 2>/dev/null)
    if [ "$ROLE" = "user" ]; then
        echo "$line" | jq -r '.content // empty' 2>/dev/null
        break
    fi
done)

if [ -z "$LAST_USER" ]; then
    exit 0
fi

# Convert to lowercase for matching
USER_LOWER=$(echo "$LAST_USER" | tr '[:upper:]' '[:lower:]')

LORE_REMINDERS=""

# ---- Extract faction names from state.json ----
FACTION_NAMES=$(cat "$STATE_FILE" | jq -r '.world.human_factions[]?.name // empty' 2>/dev/null)

# Check each faction name against the user's message
while IFS= read -r faction; do
    if [ -n "$faction" ]; then
        FACTION_LOWER=$(echo "$faction" | tr '[:upper:]' '[:lower:]')
        if echo "$USER_LOWER" | grep -qi "$FACTION_LOWER"; then
            LORE_REMINDERS="${LORE_REMINDERS}[LORE] Player referenced faction '$faction'. Load lore BEFORE responding:\n"
            # Map faction archetype to the right lore file
            ARCHETYPE=$(cat "$STATE_FILE" | jq -r ".world.human_factions[] | select(.name == \"$faction\") | .archetype // empty" 2>/dev/null)
            case "$ARCHETYPE" in
                criminal)
                    LORE_REMINDERS="${LORE_REMINDERS}  Read: runtime/phases/1-context-loading/lore/factions-nyc/criminal.md\n"
                    ;;
                faith|commune)
                    LORE_REMINDERS="${LORE_REMINDERS}  Read: runtime/phases/1-context-loading/lore/factions-nyc/ideological.md\n"
                    ;;
                *)
                    LORE_REMINDERS="${LORE_REMINDERS}  Read: runtime/phases/1-context-loading/lore/factions-nyc/major.md\n"
                    ;;
            esac
        fi
    fi
done <<< "$FACTION_NAMES"

# ---- Check for external faction/power references ----
if echo "$USER_LOWER" | grep -qi "khanate\|khan\|mongol\|horde\|great kingdom"; then
    LORE_REMINDERS="${LORE_REMINDERS}[LORE] Player referenced the Khanate. Read: runtime/phases/1-context-loading/lore/factions-external/khanate.md\n"
fi
if echo "$USER_LOWER" | grep -qi "kaelthari\|elf\|elves\|elven\|ancient.*race"; then
    LORE_REMINDERS="${LORE_REMINDERS}[LORE] Player referenced the Kaelthari. Read: runtime/phases/1-context-loading/lore/factions-external/kaelthari.md\n"
fi
if echo "$USER_LOWER" | grep -qi "marcher\|march\|dead.*march\|undead.*army"; then
    LORE_REMINDERS="${LORE_REMINDERS}[LORE] Player referenced the Marchers. Read: runtime/phases/1-context-loading/lore/factions-external/marchers.md\n"
fi

# ---- Check for location references ----
if echo "$USER_LOWER" | grep -qiE "manhattan|bronx|brooklyn|queens|staten island|central park|times square|wall street|harlem|midtown|downtown|uptown|east side|west side|grand central|penn station|bellevue|nyu|columbia|prospect park|coney island|williamsburg|astoria|flushing"; then
    LORE_REMINDERS="${LORE_REMINDERS}[LORE] Player referenced a NYC location. Read: runtime/phases/1-context-loading/lore/locations.md\n"
fi

# ---- Check for world-building questions ----
if echo "$USER_LOWER" | grep -qiE "what is|tell me about|what happened|how did|history of|why did|the transit|when did|who are|what are"; then
    if echo "$USER_LOWER" | grep -qiE "transit|vaelithar|world|sky|moon|system|magic|power|awaken"; then
        LORE_REMINDERS="${LORE_REMINDERS}[LORE] Player asking about the world/setting. Read: runtime/phases/1-context-loading/lore/core/setting.md and runtime/phases/1-context-loading/lore/core/powers-overview.md\n"
    fi
fi

# ---- Check for creature/monster references ----
if echo "$USER_LOWER" | grep -qiE "creature|monster|beast|wildlife|animal|predator|thornwolf|blightcrawler|what.*live|what.*out there|dangerous.*thing"; then
    LORE_REMINDERS="${LORE_REMINDERS}[LORE] Player asking about creatures. Read: runtime/phases/1-context-loading/lore/creatures.md\n"
fi

# ---- Check for geography questions ----
if echo "$USER_LOWER" | grep -qiE "geography|terrain|wilderness|forest|mountain|river|beyond.*city|outside.*city|border|perimeter|map"; then
    LORE_REMINDERS="${LORE_REMINDERS}[LORE] Player asking about geography. Read: runtime/phases/1-context-loading/lore/core/geography.md\n"
fi

# ---- Output reminders if any ----
if [ -n "$LORE_REMINDERS" ]; then
    printf "[EMERGENCE LORE LOADING REMINDER]\n%b\nLoad these lore files using the Read tool BEFORE writing your narrative response. Lore-backed responses are richer and more consistent.\n" "$LORE_REMINDERS"
fi

exit 0
