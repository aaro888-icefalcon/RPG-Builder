#!/bin/bash
# =============================================================================
# EMERGENCE RPG — PostToolUse Hook: CLI Output Reminder (Enhanced)
# =============================================================================
# Runs after a Bash tool call completes. If the command was an emergence_cli.py
# call, parses the ACTUAL CLI output and injects command-specific enforcement
# with exact values from the result — so the GM can't ignore or misrepresent them.
#
# Hook event: PostToolUse (matcher: Bash)
# Exit 0 + stdout with additionalContext = context injected
# =============================================================================

INPUT=$(cat)

# Extract the command that was run
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
if [ -z "$COMMAND" ]; then
    exit 0
fi

# Only process emergence_cli.py calls
if ! echo "$COMMAND" | grep -q "emergence_cli"; then
    exit 0
fi

# Extract the tool output (CLI result)
TOOL_OUTPUT=$(echo "$INPUT" | jq -r '.tool_output // empty' 2>/dev/null)

# ---- Check for CLI errors first ----
if echo "$TOOL_OUTPUT" | grep -q '"error": true\|"error":true'; then
    ERROR_MSG=$(echo "$TOOL_OUTPUT" | jq -r '.message // "unknown error"' 2>/dev/null)
    echo "{\"additionalContext\": \"[EMERGENCE HOOK] CLI ERROR: The command failed with: $ERROR_MSG. You MUST re-run with correct parameters. Do NOT proceed with narrative until the CLI succeeds.\"}"
    exit 0
fi

# Determine which CLI subcommand was run and parse output
if echo "$COMMAND" | grep -q "move "; then
    # Parse the move result for exact outcome
    TIER_NAME=$(echo "$TOOL_OUTPUT" | jq -r '.outcome.tier_name // "UNKNOWN"' 2>/dev/null)
    ROLL_TOTAL=$(echo "$TOOL_OUTPUT" | jq -r '.roll.total // "?"' 2>/dev/null)
    DICE=$(echo "$TOOL_OUTPUT" | jq -r '.roll.dice // "?"' 2>/dev/null)
    POSITION=$(echo "$TOOL_OUTPUT" | jq -r '.position.level // "risky"' 2>/dev/null)
    EFFECT=$(echo "$TOOL_OUTPUT" | jq -r '.effect.level // "standard"' 2>/dev/null)
    GM_MOVES=$(echo "$TOOL_OUTPUT" | jq -r '.outcome.suggested_gm_moves[]? // empty' 2>/dev/null | head -4 | tr '\n' ', ' | sed 's/,$//')
    IS_CRIT=$(echo "$TOOL_OUTPUT" | jq -r '.roll.is_crit // false' 2>/dev/null)
    IS_FUMBLE=$(echo "$TOOL_OUTPUT" | jq -r '.roll.is_fumble // false' 2>/dev/null)
    DMG_RANGE=$(echo "$TOOL_OUTPUT" | jq -r '.outcome.damage_range // "none"' 2>/dev/null)

    CONTEXT="[EMERGENCE HOOK] MOVE RESULT: $TIER_NAME (Roll: $DICE = $ROLL_TOTAL, Position: $POSITION, Effect: $EFFECT)"

    case "$TIER_NAME" in
        "CRITICAL")
            CONTEXT="$CONTEXT\nThe player CRITICALLY SUCCEEDED. Narrate a spectacular success with bonus effect beyond what they asked for. Great effect level applies."
            ;;
        "FULL HIT")
            CONTEXT="$CONTEXT\nClean success at $EFFECT effect level. Narrate the success without complications."
            ;;
        "PARTIAL HIT")
            CONTEXT="$CONTEXT\nSuccess WITH complication. You MUST present a real complication and let the player choose: reduced effect OR accept the consequence. Suggested GM moves: $GM_MOVES"
            ;;
        "MISS")
            if [ "$POSITION" = "controlled" ]; then
                CONTEXT="$CONTEXT\nFAILURE on controlled position. Apply a SOFT move only. Suggested: $GM_MOVES"
            elif [ "$POSITION" = "risky" ]; then
                CONTEXT="$CONTEXT\nFAILURE on risky position. Apply a HARD move OR two soft moves. Suggested: $GM_MOVES"
            elif [ "$POSITION" = "desperate" ]; then
                CONTEXT="$CONTEXT\nFAILURE on DESPERATE position. Apply a HARD move — this should HURT. Damage range: $DMG_RANGE. Suggested: $GM_MOVES"
            fi
            ;;
    esac

    if [ "$IS_FUMBLE" = "true" ]; then
        CONTEXT="$CONTEXT\nFUMBLE (double 1s)! This is catastrophic. Apply the worst reasonable consequence."
    fi

    CONTEXT="$CONTEXT\nNarrate based ONLY on this result. End with What do you do? Update state.json."

    echo "{\"additionalContext\": $(echo "$CONTEXT" | jq -Rs .)}"

elif echo "$COMMAND" | grep -q "attack "; then
    # Parse attack result
    HIT_BAND=$(echo "$TOOL_OUTPUT" | jq -r '.hit_band // "unknown"' 2>/dev/null)
    DAMAGE=$(echo "$TOOL_OUTPUT" | jq -r '.final_damage // 0' 2>/dev/null)
    ATTACKER=$(echo "$TOOL_OUTPUT" | jq -r '.attacker // "?"' 2>/dev/null)
    TARGET=$(echo "$TOOL_OUTPUT" | jq -r '.target // "?"' 2>/dev/null)
    ROLL_TOTAL=$(echo "$TOOL_OUTPUT" | jq -r '.roll_total // "?"' 2>/dev/null)

    CONTEXT="[EMERGENCE HOOK] ATTACK RESULT: $ATTACKER → $TARGET | Hit Band: $HIT_BAND | Roll: $ROLL_TOTAL | Damage: $DAMAGE"

    case "$HIT_BAND" in
        "crit")
            CONTEXT="$CONTEXT\nCRITICAL HIT! Apply $DAMAGE damage (x2). Narrate devastating wound with specific body location."
            ;;
        "exceptional")
            CONTEXT="$CONTEXT\nExceptional hit. Apply $DAMAGE damage (x1.25). Solid, clean strike."
            ;;
        "hit")
            CONTEXT="$CONTEXT\nStandard hit. Apply EXACTLY $DAMAGE damage. Describe the wound specifically."
            ;;
        "graze")
            CONTEXT="$CONTEXT\nGraze. Apply $DAMAGE damage (x0.5). Minor wound — shallow cut, bruise, glancing blow."
            ;;
        "miss")
            CONTEXT="$CONTEXT\nMISS. Zero damage. The attack fails — do NOT soften this into a 'near miss that grazes'. It MISSED."
            ;;
    esac

    CONTEXT="$CONTEXT\nApply EXACT damage. Update HP in combat state and state.json. Display updated combat format."

    echo "{\"additionalContext\": $(echo "$CONTEXT" | jq -Rs .)}"

elif echo "$COMMAND" | grep -q "creatures "; then
    # Must check "creatures" before "creature" (substring match)
    CREATURE_COUNT=$(echo "$TOOL_OUTPUT" | jq -r '.creatures | length // 0' 2>/dev/null)
    echo "{\"additionalContext\": \"[EMERGENCE HOOK] ENCOUNTER GROUP generated: $CREATURE_COUNT creatures. Display ALL in a stat table — every creature gets its own row with Name | HP | DEF | ATK | DMG | Behavior. Use ONLY these stats. Add to state.json combat_state.\"}"

elif echo "$COMMAND" | grep -q "creature "; then
    CREATURE_NAME=$(echo "$TOOL_OUTPUT" | jq -r '.name // "Unknown"' 2>/dev/null)
    CREATURE_HP=$(echo "$TOOL_OUTPUT" | jq -r '.hp.max // "?"' 2>/dev/null)
    CREATURE_ATK=$(echo "$TOOL_OUTPUT" | jq -r '.attack // "?"' 2>/dev/null)
    CREATURE_DEF=$(echo "$TOOL_OUTPUT" | jq -r '.defense // "?"' 2>/dev/null)
    CREATURE_DMG=$(echo "$TOOL_OUTPUT" | jq -r '.damage // "?"' 2>/dev/null)
    ENCOUNTER_CTX=$(echo "$TOOL_OUTPUT" | jq -r '.encounter_context.activity // ""' 2>/dev/null)

    echo "{\"additionalContext\": \"[EMERGENCE HOOK] CREATURE: $CREATURE_NAME (HP:$CREATURE_HP ATK:+$CREATURE_ATK DEF:$CREATURE_DEF DMG:$CREATURE_DMG). Display these EXACT stats in a table. Encounter context: $ENCOUNTER_CTX. Add to state.json.\"}"

elif echo "$COMMAND" | grep -q "clock-tick "; then
    CLOCK_NAME=$(echo "$TOOL_OUTPUT" | jq -r '.clock_name // "?"' 2>/dev/null)
    NEW_VALUE=$(echo "$TOOL_OUTPUT" | jq -r '.new_value // "?"' 2>/dev/null)
    MAX_VALUE=$(echo "$TOOL_OUTPUT" | jq -r '.max_value // "?"' 2>/dev/null)
    DISPLAY=$(echo "$TOOL_OUTPUT" | jq -r '.display // "?"' 2>/dev/null)
    COMPLETED=$(echo "$TOOL_OUTPUT" | jq -r '.completed // false' 2>/dev/null)

    CONTEXT="[EMERGENCE HOOK] CLOCK TICKED: $CLOCK_NAME $NEW_VALUE/$MAX_VALUE $DISPLAY"

    if [ "$COMPLETED" = "true" ]; then
        CONTEXT="$CONTEXT\n⚠️ CLOCK COMPLETE! $CLOCK_NAME has filled! This is a MAJOR WORLD EVENT. Stop everything. Announce completion dramatically. Execute the clock's completion effect. The world has CHANGED."
    fi

    CONTEXT="$CONTEXT\nDisplay in World Pulse format:\n## World Pulse — Day X, [Time]\n**News:** [event]\n**Rumors:** \"[quote]\" — [source]\n**Trends:** $CLOCK_NAME ⧗ $DISPLAY\nUpdate clock value in state.json."

    echo "{\"additionalContext\": $(echo "$CONTEXT" | jq -Rs .)}"

elif echo "$COMMAND" | grep -q "npc "; then
    NPC_NAME=$(echo "$TOOL_OUTPUT" | jq -r '.name // "Unknown"' 2>/dev/null)
    NPC_AMBITION=$(echo "$TOOL_OUTPUT" | jq -r '.active_ambition // "unknown"' 2>/dev/null)
    NPC_DREAD=$(echo "$TOOL_OUTPUT" | jq -r '.active_dread // "unknown"' 2>/dev/null)
    NPC_LEVERAGE=$(echo "$TOOL_OUTPUT" | jq -r '.leverage // "unknown"' 2>/dev/null)
    NPC_DISPOSITION=$(echo "$TOOL_OUTPUT" | jq -r '.disposition // "neutral"' 2>/dev/null)

    echo "{\"additionalContext\": \"[EMERGENCE HOOK] NPC: $NPC_NAME (Disposition: $NPC_DISPOSITION)\nWants: $NPC_AMBITION\nFears: $NPC_DREAD\nLeverage: $NPC_LEVERAGE\nThis NPC has their OWN agenda. Do NOT make them a quest giver. They have problems and goals independent of the player. Show their agenda through behavior and dialogue. Add to known_npcs in state.json.\"}"

elif echo "$COMMAND" | grep -q "loot "; then
    LOOT_CATEGORY=$(echo "$TOOL_OUTPUT" | jq -r '.category // "nothing"' 2>/dev/null)
    LOOT_DROPPED=$(echo "$TOOL_OUTPUT" | jq -r '.dropped // false' 2>/dev/null)

    if [ "$LOOT_CATEGORY" = "nothing" ] || [ "$LOOT_DROPPED" = "false" ]; then
        echo '{"additionalContext": "[EMERGENCE HOOK] LOOT RESULT: NOTHING. The player gets NO items from this enemy. Do NOT supplement with additional items. Do NOT describe finding anything useful on the body. Do NOT have the enemy drop a weapon. NOTHING means NOTHING. Scarcity is real. 85% of standard monsters drop nothing. This is working as intended."}'
    else
        echo "{\"additionalContext\": \"[EMERGENCE HOOK] LOOT RESULT: $LOOT_CATEGORY item dropped. Add this to the player's inventory in state.json. Describe finding it narratively — but it should feel like a rare, notable find, not routine.\"}"
    fi

elif echo "$COMMAND" | grep -q "session-zero "; then
    echo '{"additionalContext": "[EMERGENCE HOOK] SESSION ZERO complete. Save this as state.json in ./campaigns/[name]/state.json. Present factions and threats to the player. Proceed to character creation. Do NOT start gameplay until character is fully created via the character CLI."}'

elif echo "$COMMAND" | grep -q "scene "; then
    echo '{"additionalContext": "[EMERGENCE HOOK] SCENE generated. Use the atmosphere, zones, and encounter data from this output. Update current_scene in state.json. Do NOT add encounters beyond what was generated — run creature CLI if you need more."}'

elif echo "$COMMAND" | grep -q "character "; then
    echo '{"additionalContext": "[EMERGENCE HOOK] CHARACTER stats generated. Use EXACT stats from this output. Save to character section of state.json. The derived stats (HP, Stamina, Mana, Composure) are calculated by the script — trust them, do not recalculate."}'
fi

exit 0
