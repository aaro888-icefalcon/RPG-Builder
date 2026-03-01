#!/bin/bash
# =============================================================================
# EMERGENCE RPG — Stop Hook: Enforce Master Router (classify-action)
# =============================================================================
# Every gameplay turn must run a core CLI command. The master router
# (classify-action) determines which. Only DEVELOPMENT: prefix in the
# user message bypasses this requirement.
#
# Hook event: Stop
# Exit 0 + JSON {decision: "block", reason: "..."} = force retry
# Exit 0 + no output = allow
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

# ---- RPG session detection ----
CAMPAIGN_DIR="$PROJECT_DIR/runtime/campaigns"
ALT_CAMPAIGN_DIR="$PROJECT_DIR/campaigns"

IN_RPG_SESSION=false
if [ -d "$CAMPAIGN_DIR" ] || [ -d "$ALT_CAMPAIGN_DIR" ]; then
    TAIL_CONTENT=$(tail -20 "$TRANSCRIPT_PATH" 2>/dev/null || echo "")
    if echo "$TAIL_CONTENT" | grep -qi \
        "emergence\|what do you do\|emergence_cli\|state\.json\|world pulse\|clock-tick\|combat.*round\|HP:.*Stamina\|session.zero\|Vaelithar"; then
        IN_RPG_SESSION=true
    fi
fi

if [ "$IN_RPG_SESSION" = false ]; then
    exit 0
fi

# =============================================================================
# Section B: Exception paths
# =============================================================================

# ---- Exception 1: DEVELOPMENT: prefix in user message ----
# This is the ONLY way to bypass the master router. [D17, D21]
LAST_USER=$(tac "$TRANSCRIPT_PATH" 2>/dev/null | while IFS= read -r line; do
    ROLE=$(echo "$line" | jq -r '.role // empty' 2>/dev/null)
    if [ "$ROLE" = "user" ]; then
        echo "$line" | jq -r '.content // empty' 2>/dev/null
        break
    fi
done)

if echo "$LAST_USER" | grep -qE "^\s*DEVELOPMENT:"; then
    exit 0  # Explicit development mode — no CLI required
fi

# ---- Exception 2: No state file → pre-session-zero ----
STATE_FILE=""
if [ -d "$PROJECT_DIR/campaigns" ]; then
    STATE_FILE=$(find "$PROJECT_DIR/campaigns" -name "state.json" -maxdepth 2 2>/dev/null | head -1)
fi
if [ -z "$STATE_FILE" ] && [ -d "$PROJECT_DIR/runtime/campaigns" ]; then
    STATE_FILE=$(find "$PROJECT_DIR/runtime/campaigns" -name "state.json" -maxdepth 2 2>/dev/null | head -1)
fi

if [ -z "$STATE_FILE" ]; then
    exit 0
fi

# ---- Exception 3: Combat active → handled by dedicated combat hooks ----
if [ -f "$STATE_FILE" ]; then
    COMBAT_ACTIVE=$(cat "$STATE_FILE" | jq -r '.current_scene.combat_state.active // false' 2>/dev/null)
    if [ "$COMBAT_ACTIVE" = "true" ]; then
        exit 0
    fi
fi

# ---- Exception 4: Session setup (multi-turn session-zero conversation) ----
# classify-action was called at the START of session-zero. These are follow-up
# turns within the session-zero flow (character creation, aspect selection, etc.)
# where the GM is iterating with the player. Not a new gameplay turn.
LAST_ASSISTANT=$(tac "$TRANSCRIPT_PATH" 2>/dev/null | while IFS= read -r line; do
    ROLE=$(echo "$line" | jq -r '.role // empty' 2>/dev/null)
    if [ "$ROLE" = "assistant" ]; then
        echo "$line" | jq -r '.content // empty' 2>/dev/null
        break
    fi
done)

if echo "$LAST_ASSISTANT" | grep -qiE \
    "campaign name|session zero|choose.*aspect|choose.*archetype|select.*form|which campaign|character concept|what.*class|new campaign"; then
    exit 0
fi

# =============================================================================
# Section C: CLI call detection
# =============================================================================

RECENT_TRANSCRIPT=$(tail -50 "$TRANSCRIPT_PATH" 2>/dev/null || echo "")

CLASSIFY_CALLED=false
if echo "$RECENT_TRANSCRIPT" | grep -q "classify-action"; then
    CLASSIFY_CALLED=true
fi

HIGH_VALUE_CLI=false
if echo "$RECENT_TRANSCRIPT" | grep -qE "emergence_cli.py (move|attack|evaluate-behavior) "; then
    HIGH_VALUE_CLI=true
fi

SCENE_PRESSURE_ONLY=false
if echo "$RECENT_TRANSCRIPT" | grep -q "scene-pressure"; then
    if ! echo "$RECENT_TRANSCRIPT" | grep -qE \
        "emergence_cli.py (move|attack|evaluate-behavior|classify-action) "; then
        SCENE_PRESSURE_ONLY=true
    fi
fi

ANY_CLI=false
if echo "$RECENT_TRANSCRIPT" | grep -q "emergence_cli"; then
    ANY_CLI=true
fi

# =============================================================================
# Section D: Narrative resolution detection (for Path 3 only)
# =============================================================================

RESOLVES_ACTION=false

# Pattern 1: "you [resolution verb]"
if echo "$LAST_ASSISTANT" | grep -qiE \
    "you (succeed|manage|fail|stumble|slip|sneak past|convince|find|discover|dodge|block|land a|hit|miss|struggle|push through|climb|jump|break|pick|grab|escape|avoid|resist|overcome|reach|cross|enter|open|unlock|solve|figure out|notice|spot|detect|sense|hear|smell|read|decipher|craft|build|repair|heal|negotiate|barter|persuade|deceive|intimidate|charm|calm|rally|provoke|disarm|outrun|outmaneuver|overpower|outsmart)"; then
    RESOLVES_ACTION=true
fi

# Pattern 2: Environmental resolution
if echo "$LAST_ASSISTANT" | grep -qiE \
    "the (lock|door|wall|barrier|trap|puzzle|mechanism|device|gate|chest|container|rope|chain|window|hatch|grate|panel) (opens|breaks|yields|gives way|activates|disarms|clicks|releases|snaps|crumbles|shatters|slides|swings)"; then
    RESOLVES_ACTION=true
fi

# Pattern 3: Effort-framed resolution
if echo "$LAST_ASSISTANT" | grep -qiE \
    "(with (a|great|considerable) (effort|strain|grunt|heave)|after (a|some|several) (moment|attempt|tries?|seconds?))[^.]*you"; then
    RESOLVES_ACTION=true
fi

# =============================================================================
# Section E: Decision tree
# =============================================================================
# Core principle [D7, D16, D17]: The master router runs every gameplay turn.
# DEVELOPMENT: is the only escape (checked in Section B). If we reach this
# point, a CLI must have run.

# Path 1: classify-action was called → ALLOW (master router ran)
if [ "$CLASSIFY_CALLED" = true ]; then exit 0; fi

# Path 2: High-value CLI ran (move/attack/evaluate-behavior) → ALLOW
if [ "$HIGH_VALUE_CLI" = true ]; then exit 0; fi

# Path 3: Only scene-pressure ran → check for drift
if [ "$SCENE_PRESSURE_ONLY" = true ]; then
    if [ "$RESOLVES_ACTION" = true ]; then
        REASON="CLASSIFICATION DRIFT: You ran 'scene-pressure' but narrated an action
resolution with uncertain outcome. The master router (classify-action) must run first
every turn. Run 'emergence_cli.py classify-action' then execute its required_cli.
See: hard-rules.md §Rule 5, mechanical-classification.md"
        echo "{\"decision\": \"block\", \"reason\": $(echo "$REASON" | jq -Rs .)}"
        exit 0
    fi
    exit 0  # scene-pressure + no resolution = genuine free narration → ALLOW
fi

# Path 4: Other CLI ran (world-tick, creature, npc, etc.) → ALLOW
if [ "$ANY_CLI" = true ]; then exit 0; fi

# Path 5: NO CLI at all → BLOCK
# Not a DEVELOPMENT: turn (checked in Section B). A CLI must have run.
REASON="MASTER ROUTER VIOLATION: No CLI executed this turn. The master router
(classify-action) must run EVERY gameplay turn — it determines which CLI commands
are required. Even OOC questions (// or [meta]) go through the router.
Only 'DEVELOPMENT:' prefix bypasses this requirement.
Run: emergence_cli.py classify-action --player-message '<message>' --scene-json '<context>'
See: hard-rules.md §Rule 5"
echo "{\"decision\": \"block\", \"reason\": $(echo "$REASON" | jq -Rs .)}"
exit 0
