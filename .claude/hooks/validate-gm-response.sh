#!/bin/bash
# =============================================================================
# EMERGENCE RPG — Stop Hook: GM Response Validator
# =============================================================================
# Runs when Claude finishes responding. Checks whether the GM followed
# the Response Gate protocol. If violations are found, blocks the stop
# and forces Claude to self-correct.
#
# Hook event: Stop
# Exit 0 + JSON {decision: "block", reason: "..."} = force retry
# Exit 0 + no output = allow
# =============================================================================

INPUT=$(cat)

# Check if this is already a stop-hook retry to prevent infinite loops
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
    exit 0
fi

# Get the transcript path
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty')
if [ -z "$TRANSCRIPT_PATH" ] || [ ! -f "$TRANSCRIPT_PATH" ]; then
    exit 0
fi

# Get the project directory
PROJECT_DIR=$(echo "$INPUT" | jq -r '.cwd // empty')
if [ -z "$PROJECT_DIR" ]; then
    exit 0
fi

# ---- Determine if we're in an active Emergence RPG session ----
# Check for campaign directories or state files
CAMPAIGN_DIR="$PROJECT_DIR/runtime/campaigns"
ALT_CAMPAIGN_DIR="$PROJECT_DIR/campaigns"

IN_RPG_SESSION=false
if [ -d "$CAMPAIGN_DIR" ] || [ -d "$ALT_CAMPAIGN_DIR" ]; then
    # Check if recent messages reference emergence/RPG content
    # Look at the last few lines of transcript for RPG indicators
    TAIL_CONTENT=$(tail -20 "$TRANSCRIPT_PATH" 2>/dev/null || echo "")
    if echo "$TAIL_CONTENT" | grep -qi "emergence\|what do you do\|emergence_cli\|state\.json\|world pulse\|clock-tick\|combat.*round\|HP:.*Stamina\|session.zero\|Vaelithar"; then
        IN_RPG_SESSION=true
    fi
fi

if [ "$IN_RPG_SESSION" = false ]; then
    exit 0
fi

# ---- Extract the last assistant turn from the transcript ----
# The transcript is JSONL. Get the last assistant message content.
LAST_ASSISTANT=$(tac "$TRANSCRIPT_PATH" 2>/dev/null | while IFS= read -r line; do
    ROLE=$(echo "$line" | jq -r '.role // empty' 2>/dev/null)
    if [ "$ROLE" = "assistant" ]; then
        echo "$line" | jq -r '.content // empty' 2>/dev/null
        break
    fi
done)

# If we can't parse the transcript, allow
if [ -z "$LAST_ASSISTANT" ]; then
    exit 0
fi

# ---- Check if any Bash tool calls ran emergence_cli.py in this turn ----
# Look for tool_use entries with emergence_cli in the recent transcript
RECENT_TOOL_CALLS=$(tail -50 "$TRANSCRIPT_PATH" 2>/dev/null | grep -c "emergence_cli" || echo "0")

# ---- Check if the last user message was a gameplay action ----
LAST_USER=$(tac "$TRANSCRIPT_PATH" 2>/dev/null | while IFS= read -r line; do
    ROLE=$(echo "$line" | jq -r '.role // empty' 2>/dev/null)
    if [ "$ROLE" = "user" ]; then
        echo "$line" | jq -r '.content // empty' 2>/dev/null
        break
    fi
done)

# Determine if user message looks like a gameplay action (not meta/OOC)
IS_GAMEPLAY_ACTION=false
if echo "$LAST_USER" | grep -qiE "^(I |i )(try|want|go|head|walk|run|attack|sneak|hide|convince|talk|ask|look|examine|search|open|grab|pick|climb|jump|swing|cast|use|throw|dodge|defend|move|push|pull|break|check|investigate|follow|approach|retreat|flee|fight|shoot|stab|slash|block|parry|heal|bandage|rest|eat|drink|trade|barter|offer|negotiate|threaten|intimidate|lie|deceive|bluff|persuade|scout|explore|enter|exit|leave)"; then
    IS_GAMEPLAY_ACTION=true
fi

# ---- Collect violations ----
VIOLATIONS=""

# VIOLATION 1: Player took an action but no CLI was run
if [ "$IS_GAMEPLAY_ACTION" = true ] && [ "$RECENT_TOOL_CALLS" = "0" ]; then
    # Check if the response contains narrative resolution (indicating the action was resolved without CLI)
    if echo "$LAST_ASSISTANT" | grep -qiE "you (succeed|manage|slip|sneak|convince|find|discover|dodge|block|land|hit|miss|fail|stumble|fall)"; then
        VIOLATIONS="${VIOLATIONS}CRITICAL: You resolved a player action without running the CLI. The player said: '$(echo "$LAST_USER" | head -c 100)'. You MUST run 'emergence_cli.py move' BEFORE narrating the outcome. Run the CLI now and rewrite your response based on the actual roll result.\n\n"
    fi
fi

# VIOLATION 2: Missing "What do you do?"
if ! echo "$LAST_ASSISTANT" | grep -qi "what do you do"; then
    # Allow exceptions for session setup, character creation prompts, and meta responses
    if ! echo "$LAST_ASSISTANT" | grep -qiE "(session zero|campaign name|choose.*aspect|choose.*archetype|select.*form|which campaign|saved.*session|end of session|character creation)"; then
        VIOLATIONS="${VIOLATIONS}MISSING PLAYER PROMPT: Your response does not end with 'What do you do?' Every gameplay response MUST end with this prompt and then STOP. Add it now.\n\n"
    fi
fi

# VIOLATION 3: Scene transition without clock-tick
if echo "$LAST_ASSISTANT" | grep -qiE "(walk|head|move|travel|arrive|enter|leave|exit|reach|approach).*(to|into|toward|the|a) [A-Z]"; then
    if ! echo "$LAST_ASSISTANT" | grep -qi "world pulse\|clock.*tick\|⧗\|●\|○"; then
        if [ "$RECENT_TOOL_CALLS" = "0" ] || ! tail -50 "$TRANSCRIPT_PATH" 2>/dev/null | grep -q "clock-tick"; then
            VIOLATIONS="${VIOLATIONS}MISSING CLOCK TICK: A scene transition occurred but you did not run 'emergence_cli.py clock-tick' or display a World Pulse. Run clock-tick for 1-2 relevant clocks and add the World Pulse block before your narrative.\n\n"
        fi
    fi
fi

# VIOLATION 4: Creature described without CLI stats
if echo "$LAST_ASSISTANT" | grep -qiE "(creature|beast|monster|wolf|insect|spider|thing|horror|predator|animal).*(emerge|appear|attack|lunge|charge|snarl|growl|screech|skitter)"; then
    if ! echo "$LAST_ASSISTANT" | grep -qE "\| .* \| [0-9]+/[0-9]+ \||\| HP \||\| DEF \|"; then
        if [ "$RECENT_TOOL_CALLS" = "0" ] || ! tail -50 "$TRANSCRIPT_PATH" 2>/dev/null | grep -qE "creature|creatures"; then
            VIOLATIONS="${VIOLATIONS}MISSING CREATURE STATS: You described a creature or enemy without generating stats via 'emergence_cli.py creature'. Run the creature CLI first, then display the stat block table in your response.\n\n"
        fi
    fi
fi

# VIOLATION 5: Auto-resolving player dialogue
if echo "$LAST_ASSISTANT" | grep -qiE "you (say|tell|explain|reply|respond|answer|agree|refuse|offer|ask|demand|request|promise|lie|admit|confess|reveal|announce|shout|whisper) "; then
    # Check it's not quoting an NPC
    if echo "$LAST_ASSISTANT" | grep -qiE "^[^\"]*you (say|tell|explain|reply|respond|answer) "; then
        VIOLATIONS="${VIOLATIONS}PLAYER AGENCY VIOLATION: You wrote the player character's dialogue. You said something like 'you tell them...' or 'you say...' — the player decides what their character says. Present the situation and ask 'What do you do?' instead.\n\n"
    fi
fi

# VIOLATION 6: Heroic descriptors for low-level characters
if echo "$LAST_ASSISTANT" | grep -qiE "(hero|champion|legend|master|commander|warlord|lord|lady|apex)"; then
    # Check if character is low level by looking for level indicators
    if echo "$LAST_ASSISTANT" | grep -qiE "L[0-9]|level [0-9]|Level [1-9][^0-9]|Level 1[0-4]" || tail -100 "$TRANSCRIPT_PATH" 2>/dev/null | grep -qiE "\"level\": [0-9][^0-9]|\"level\": 1[0-4]"; then
        VIOLATIONS="${VIOLATIONS}HEROIC DESCRIPTOR VIOLATION: You used a heroic descriptor (hero, champion, legend, etc.) for a character below Level 15. Use 'survivor', 'scavenger', 'nobody', 'refugee' instead.\n\n"
    fi
fi

# VIOLATION 7: Forced consequence not narrated
# If move CLI was called and output contains forced_consequence, check that narrative references it
if tail -80 "$TRANSCRIPT_PATH" 2>/dev/null | grep -qiE "forced.consequence|forced_consequence"; then
    FORCED_TYPE=$(tail -80 "$TRANSCRIPT_PATH" 2>/dev/null | grep -oiE "(deal_damage|tick_clock|worsen_position|separate|destroy_resource|capture|reveal_threat|use_resources)" | head -1 || echo "")
    if [ -n "$FORCED_TYPE" ]; then
        CONSEQUENCE_NARRATED=false
        case "$FORCED_TYPE" in
            deal_damage)
                echo "$LAST_ASSISTANT" | grep -qiE "damage|HP.*→|takes? [0-9]|wound|bleed|struck|hit" && CONSEQUENCE_NARRATED=true
                ;;
            tick_clock)
                echo "$LAST_ASSISTANT" | grep -qiE "clock|⧗|advance|progress|tick" && CONSEQUENCE_NARRATED=true
                ;;
            *)
                # For other types, allow (fuzzy matching is imprecise for rarer types)
                CONSEQUENCE_NARRATED=true
                ;;
        esac
        if [ "$CONSEQUENCE_NARRATED" = false ]; then
            VIOLATIONS="${VIOLATIONS}FORCED CONSEQUENCE NOT NARRATED: The move CLI returned forced consequence '$FORCED_TYPE' but your narrative does not appear to include it. v5.0 rule: CLI-selected consequences are BINDING. Narrate the specific consequence.\n\n"
        fi
    fi
fi

# VIOLATION 8: npc CLI used for combat NPC (should be awakened-npc)
if tail -50 "$TRANSCRIPT_PATH" 2>/dev/null | grep -qE "emergence_cli.py npc " && ! tail -50 "$TRANSCRIPT_PATH" 2>/dev/null | grep -q "awakened-npc"; then
    if echo "$LAST_ASSISTANT" | grep -qiE "(attacks?|fights?|combat|initiative|enemy|hostile).*(NPC|character|warrior|soldier|guard|bandit|raider)|(NPC|warrior|soldier|guard|bandit|raider).*(attacks?|fights?|combat|hostile)"; then
        VIOLATIONS="${VIOLATIONS}WRONG NPC CLI: You used 'npc' CLI for an NPC that enters combat. Use 'awakened-npc' CLI instead — it generates full combat stats and powers. The 'npc' CLI is for social-only NPCs.\n\n"
    fi
fi

# ---- Report violations ----
if [ -n "$VIOLATIONS" ]; then
    REASON=$(printf "EMERGENCE RPG RESPONSE GATE VIOLATIONS DETECTED:\n\n%b\nYou MUST fix these violations before your response is shown to the player. Re-examine runtime/phases/3-resolution/skills/core/move-resolution.md and runtime/phases/1-context-loading/references/hard-rules.md §Pre-Response Checklist. Correct your response now." "$VIOLATIONS")

    echo "{\"decision\": \"block\", \"reason\": $(echo "$REASON" | jq -Rs .)}"
    exit 0
fi

# All checks passed
exit 0
