#!/bin/bash
# =============================================================================
# EMERGENCE RPG — Stop Hook: Narrative Principles Validator
# =============================================================================
# Checks the GM's response for narrative principle violations:
# - Alienation cues (post-Transit sensory details)
# - Scarcity language (no abundance)
# - Wound specificity (anatomical descriptions, not "you take X damage")
# - Tone calibration (desperation at low levels, not triumph)
# - NPC depth (agenda indicators, not quest givers)
# - Power fantasy detection
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
TAIL_CONTENT=$(tail -30 "$TRANSCRIPT_PATH" 2>/dev/null || echo "")
if ! echo "$TAIL_CONTENT" | grep -qi "emergence\|what do you do\|emergence_cli\|state\.json\|world pulse\|clock-tick\|Vaelithar"; then
    exit 0
fi

# ---- Get last assistant response ----
LAST_ASSISTANT=$(tac "$TRANSCRIPT_PATH" 2>/dev/null | while IFS= read -r line; do
    ROLE=$(echo "$line" | jq -r '.role // empty' 2>/dev/null)
    if [ "$ROLE" = "assistant" ]; then
        echo "$line" | jq -r '.content // empty' 2>/dev/null
        break
    fi
done)

if [ -z "$LAST_ASSISTANT" ]; then
    exit 0
fi

# ---- Skip validation for meta/setup responses ----
if echo "$LAST_ASSISTANT" | grep -qiE "session zero|campaign name|choose.*aspect|choose.*archetype|select.*form|which campaign|character creation|welcome to emergence"; then
    exit 0
fi

# ---- Load state for context ----
STATE_FILE=""
if [ -d "$PROJECT_DIR/campaigns" ]; then
    STATE_FILE=$(find "$PROJECT_DIR/campaigns" -name "state.json" -maxdepth 2 2>/dev/null | head -1)
fi
if [ -z "$STATE_FILE" ] && [ -d "$PROJECT_DIR/runtime/campaigns" ]; then
    STATE_FILE=$(find "$PROJECT_DIR/runtime/campaigns" -name "state.json" -maxdepth 2 2>/dev/null | head -1)
fi

CHAR_LEVEL=0
CURRENT_DAY=0
SCENE_PHASE="post-transit"
if [ -n "$STATE_FILE" ] && [ -f "$STATE_FILE" ]; then
    CHAR_LEVEL=$(cat "$STATE_FILE" | jq -r '.character.level // 0' 2>/dev/null)
    CURRENT_DAY=$(cat "$STATE_FILE" | jq -r '.world.current_day // 0' 2>/dev/null)
    SCENE_PHASE=$(cat "$STATE_FILE" | jq -r '.current_scene.phase // "post-transit"' 2>/dev/null)
fi

VIOLATIONS=""

# ---- Check 1: Alienation Cues (post-Transit only) ----
if [ "$SCENE_PHASE" != "pre-transit" ] && [ "$CURRENT_DAY" -ge 1 ] 2>/dev/null; then
    # Response should contain at least one alienation marker
    # Check for: moons, dead electronics, ozone/mineral air, wrong sounds/echoes, System screen
    HAS_ALIENATION=false
    if echo "$LAST_ASSISTANT" | grep -qiE "moon|moons|two.*moon|dual.*moon|twin.*moon"; then
        HAS_ALIENATION=true
    fi
    if echo "$LAST_ASSISTANT" | grep -qiE "dead.*phone|dead.*electronic|no.*signal|no.*power|dark.*screen|phone.*dead|useless.*phone|no.*electricity"; then
        HAS_ALIENATION=true
    fi
    if echo "$LAST_ASSISTANT" | grep -qiE "ozone|mineral|wildflower|strange.*air|different.*smell|alien.*scent|unfamiliar.*air"; then
        HAS_ALIENATION=true
    fi
    if echo "$LAST_ASSISTANT" | grep -qiE "wrong.*echo|strange.*sound|impossible.*angle|sound.*carry|carry.*wrong|distant.*rumble"; then
        HAS_ALIENATION=true
    fi
    if echo "$LAST_ASSISTANT" | grep -qiE "system.*screen|flicker.*edge|system.*notification|HUD|interface.*glow|translucent.*text"; then
        HAS_ALIENATION=true
    fi
    if echo "$LAST_ASSISTANT" | grep -qiE "alien.*sky|strange.*sky|wrong.*sky|purple.*sky|green.*tinge|unfamiliar.*star"; then
        HAS_ALIENATION=true
    fi

    if [ "$HAS_ALIENATION" = false ]; then
        # Only flag if the response is narrative (not pure combat state display)
        WORD_COUNT=$(echo "$LAST_ASSISTANT" | wc -w | tr -d ' ')
        if [ "$WORD_COUNT" -gt 50 ]; then
            VIOLATIONS="${VIOLATIONS}ALIENATION CUE MISSING: Post-Transit narrative should include at least one sensory alienation detail (two moons, dead electronics, ozone/mineral air, wrong echoes, System screen flicker). The world is ALIEN — remind the player constantly.\n\n"
        fi
    fi
fi

# ---- Check 2: Scarcity Language ----
if echo "$LAST_ASSISTANT" | grep -qiE "you find plenty|abundant|well.stocked|fully stocked|wealth of|treasure trove|jackpot|loaded with|overflowing|bountiful|plentiful"; then
    VIOLATIONS="${VIOLATIONS}SCARCITY VIOLATION: You used abundance language ('plenty', 'well-stocked', 'abundant', etc.). Resources in Emergence are SCARCE. Show scarcity: half-empty water bottles, torn bandages, last granola bar. Every resource use is a decision.\n\n"
fi

# ---- Check 3: Wound Specificity ----
# If attack CLI ran this turn, check for wound description
if tail -50 "$TRANSCRIPT_PATH" 2>/dev/null | grep -q "emergence_cli.*attack"; then
    if echo "$LAST_ASSISTANT" | grep -qiE "you take [0-9]+ damage|deals [0-9]+ damage|suffers [0-9]+ damage|takes [0-9]+ damage"; then
        if ! echo "$LAST_ASSISTANT" | grep -qiE "arm|leg|shoulder|chest|ribs|head|face|back|side|torso|hand|finger|jaw|neck|gut|hip|thigh|forearm|shin|ankle|knee|skull|temple|ear|throat|wrist|collarbone|stomach"; then
            VIOLATIONS="${VIOLATIONS}WOUND NARRATION VIOLATION: You described damage as 'X damage' without anatomical specificity. Injuries are specific: 'the claw rakes across your forearm' not 'you take 4 damage'. Describe WHERE the wound is, HOW it looks, and what it affects.\n\n"
        fi
    fi
fi

# ---- Check 4: Tone Calibration (Level 1-10) ----
if [ "$CHAR_LEVEL" -ge 0 ] && [ "$CHAR_LEVEL" -le 10 ] 2>/dev/null; then
    if echo "$LAST_ASSISTANT" | grep -qiE "triumph|triumphs|defeats easily|heroically|effortlessly|with ease|easily overcome|dominat|glorious|magnificent|master stroke|brilliant move|flawless|perfect execution"; then
        VIOLATIONS="${VIOLATIONS}TONE VIOLATION: Character is Level $CHAR_LEVEL (Levels 1-10 = Desperation, not triumph). You used triumphant/heroic language. At this level, survival is hard-won and ugly. Use language of desperation: barely, narrowly, struggling, gasping, scraping by.\n\n"
    fi
fi

# ---- Check 5: Power Fantasy Detection ----
# Check if player succeeded at everything with zero complications
MOVE_COUNT=$(tail -50 "$TRANSCRIPT_PATH" 2>/dev/null | grep -c "emergence_cli.*move" || echo "0")
if [ "$MOVE_COUNT" -gt 1 ]; then
    # Multiple moves resolved — check if ALL were narrated as clean successes
    if echo "$LAST_ASSISTANT" | grep -qiE "succeed|success|manage|accomplish" && ! echo "$LAST_ASSISTANT" | grep -qiE "but|however|complication|cost|though|unfortunately|problem|consequence|price|difficult|struggle|barely|narrow"; then
        VIOLATIONS="${VIOLATIONS}POWER FANTASY WARNING: Multiple actions resolved with no complications or costs narrated. Even on a FULL HIT, the world should feel dangerous. Add texture — describe the effort, the near-miss, the cost of success. On PARTIAL HITs, there MUST be a complication.\n\n"
    fi
fi

# ---- Report violations ----
if [ -n "$VIOLATIONS" ]; then
    REASON=$(printf "NARRATIVE PRINCIPLE VIOLATIONS:\n\n%b\nReview runtime/phases/3-resolution/skills/core/forced-consequence.md and runtime/CLAUDE.md §9 — Narrative Principles. Fix these issues in your response." "$VIOLATIONS")

    echo "{\"decision\": \"block\", \"reason\": $(echo "$REASON" | jq -Rs .)}"
    exit 0
fi

exit 0
