#!/bin/bash
# =============================================================================
# EMERGENCE RPG — UserPromptSubmit Hook: State Context Injection
# =============================================================================
# Runs when the player submits a message. Reads state.json and injects
# current game state as context so Claude doesn't lose track of HP, clocks,
# inventory, etc. as the context window grows.
#
# This fights context decay — the #2 failure mode after skipping CLI calls.
#
# Hook event: UserPromptSubmit
# Exit 0 + stdout text = text added as context to Claude's processing
# =============================================================================

INPUT=$(cat)

PROJECT_DIR=$(echo "$INPUT" | jq -r '.cwd // empty')
if [ -z "$PROJECT_DIR" ]; then
    exit 0
fi

# ---- Find the active campaign state.json ----
STATE_FILE=""

# Check campaigns/ at project root
if [ -d "$PROJECT_DIR/campaigns" ]; then
    # Find the most recently modified state.json
    STATE_FILE=$(find "$PROJECT_DIR/campaigns" -name "state.json" -maxdepth 2 2>/dev/null | head -1)
fi

# Check runtime/campaigns/
if [ -z "$STATE_FILE" ] && [ -d "$PROJECT_DIR/runtime/campaigns" ]; then
    STATE_FILE=$(find "$PROJECT_DIR/runtime/campaigns" -name "state.json" -maxdepth 2 2>/dev/null | head -1)
fi

# No state file found — not in an active campaign
if [ -z "$STATE_FILE" ] || [ ! -f "$STATE_FILE" ]; then
    exit 0
fi

# ---- Parse state.json and build context summary ----
STATE=$(cat "$STATE_FILE")

# Extract key fields
CHAR_NAME=$(echo "$STATE" | jq -r '.character.name // "Unknown"')
CLASS_NAME=$(echo "$STATE" | jq -r '.character.class_name // "Unawakened"')
LEVEL=$(echo "$STATE" | jq -r '.character.level // 0')
HP_CUR=$(echo "$STATE" | jq -r '.character.hp.current // "?"')
HP_MAX=$(echo "$STATE" | jq -r '.character.hp.max // "?"')
STAM_CUR=$(echo "$STATE" | jq -r '.character.stamina.current // "?"')
STAM_MAX=$(echo "$STATE" | jq -r '.character.stamina.max // "?"')
MANA_CUR=$(echo "$STATE" | jq -r '.character.mana.current // "N/A"')
MANA_MAX=$(echo "$STATE" | jq -r '.character.mana.max // "N/A"')
COMP_CUR=$(echo "$STATE" | jq -r '.character.composure.current // "N/A"')
COMP_MAX=$(echo "$STATE" | jq -r '.character.composure.max // "N/A"')
PHYS_DEF=$(echo "$STATE" | jq -r '.character.physical_def // "?"')
DAY=$(echo "$STATE" | jq -r '.world.current_day // 1')
TIME=$(echo "$STATE" | jq -r '.world.current_time // "12:00"')
LOCATION=$(echo "$STATE" | jq -r '.current_scene.location // "Unknown"')
ENTROPY=$(echo "$STATE" | jq -r '.world.entropy // 50')

# Inventory
INVENTORY=$(echo "$STATE" | jq -r '.character.inventory[]? // empty' 2>/dev/null | head -15 | while read -r item; do echo "  - $item"; done)
if [ -z "$INVENTORY" ]; then
    INVENTORY="  (empty)"
fi

# Conditions
CONDITIONS=$(echo "$STATE" | jq -r '.character.conditions[]? // empty' 2>/dev/null | while read -r cond; do echo "  - $cond"; done)
if [ -z "$CONDITIONS" ]; then
    CONDITIONS="  None"
fi

# Active clocks (non-zero, from human factions and meta clocks)
CLOCKS=""
# Human faction clocks
FACTION_CLOCKS=$(echo "$STATE" | jq -r '
    .world.human_factions[]? |
    select(.clock.current > 0) |
    "  - \(.clock.name): \(.clock.current)/\(.clock.max)"
' 2>/dev/null)
# External threat clocks
THREAT_CLOCKS=$(echo "$STATE" | jq -r '
    .world.external_threats[]? |
    select(.clock.current > 0) |
    "  - \(.name): \(.clock.current)/\(.clock.max)"
' 2>/dev/null)
# Meta clocks
META_CLOCKS=$(echo "$STATE" | jq -r '
    .world.meta_clocks[]? |
    select(.current > 0) |
    "  - \(.name): \(.current)/\(.max)"
' 2>/dev/null)

ALL_CLOCKS="${FACTION_CLOCKS}${THREAT_CLOCKS:+
$THREAT_CLOCKS}${META_CLOCKS:+
$META_CLOCKS}"

if [ -z "$ALL_CLOCKS" ]; then
    CLOCKS="  No clocks have advanced yet."
else
    CLOCKS="$ALL_CLOCKS"
fi

# Attributes (for move CLI stat-score reference)
MIG=$(echo "$STATE" | jq -r '.character.attributes.might // 10')
AGI=$(echo "$STATE" | jq -r '.character.attributes.agility // 10')
FOR=$(echo "$STATE" | jq -r '.character.attributes.fortitude // 10')
PRC=$(echo "$STATE" | jq -r '.character.attributes.precision // 10')
INT=$(echo "$STATE" | jq -r '.character.attributes.intellect // 10')
WIS=$(echo "$STATE" | jq -r '.character.attributes.wisdom // 10')
WIL=$(echo "$STATE" | jq -r '.character.attributes.willpower // 10')
PRE=$(echo "$STATE" | jq -r '.character.attributes.presence // 10')

# ---- Combat State Detection ----
COMBAT_SECTION=""
COMBAT_STATE=$(echo "$STATE" | jq -r '.current_scene.combat_state // empty' 2>/dev/null)
if [ -n "$COMBAT_STATE" ] && [ "$COMBAT_STATE" != "null" ]; then
    COMBAT_ROUND=$(echo "$STATE" | jq -r '.current_scene.combat_state.round // 1' 2>/dev/null)
    COMBAT_ENEMIES=$(echo "$STATE" | jq -r '
        .current_scene.combat_state.enemies[]? |
        "  - \(.name): HP \(.hp.current // "?")/\(.hp.max // "?") | DEF \(.defense // "?") | ATK +\(.attack // "?") | DMG \(.damage // "?")"
    ' 2>/dev/null)
    COMBAT_INITIATIVE=$(echo "$STATE" | jq -r '
        [.current_scene.combat_state.initiative[]?] | join(" → ")
    ' 2>/dev/null)
    PLAYER_STANCE=$(echo "$STATE" | jq -r '.current_scene.combat_state.player_stance // "balanced"' 2>/dev/null)
    PLAYER_AP=$(echo "$STATE" | jq -r '.current_scene.combat_state.player_ap // 3' 2>/dev/null)

    COMBAT_SECTION="
⚔️ COMBAT ACTIVE — Round $COMBAT_ROUND
Stance: $PLAYER_STANCE | AP: $PLAYER_AP
Initiative: ${COMBAT_INITIATIVE:-Not set}
ENEMIES:
${COMBAT_ENEMIES:-  (none)}
You MUST display the full combat format (HP/Stamina bar, Stance/AP, enemy table, available actions) in your response."
fi

# ---- Resource Warnings ----
WARNINGS=""

# Critical HP warning (≤25% of max)
if [ "$HP_MAX" -gt 0 ] 2>/dev/null; then
    HP_THRESHOLD=$(( HP_MAX / 4 ))
    if [ "$HP_CUR" -le "$HP_THRESHOLD" ] 2>/dev/null && [ "$HP_CUR" -gt 0 ] 2>/dev/null; then
        WARNINGS="${WARNINGS}
⚠️ CRITICALLY WOUNDED ($HP_CUR/$HP_MAX HP). Narrate pain, impaired movement, blurred vision, blood. Death is one bad roll away. Every action should feel like it costs something."
    fi
    if [ "$HP_CUR" -le 0 ] 2>/dev/null; then
        WARNINGS="${WARNINGS}
💀 CHARACTER IS AT 0 HP. They are DYING or incapacitated. No normal actions possible. Apply Death's Door rules."
    fi
fi

# Stamina depletion
if [ "$STAM_CUR" = "0" ] 2>/dev/null; then
    WARNINGS="${WARNINGS}
⚠️ STAMINA DEPLETED (0/$STAM_MAX). Character is exhausted. Physical actions cost extra, disadvantage on MIG/AGI/FOR rolls. Narrate gasping, trembling, leaden limbs."
fi

# Mana depletion
if [ "$MANA_CUR" = "0" ] && [ "$MANA_MAX" != "N/A" ] && [ "$MANA_MAX" != "0" ] 2>/dev/null; then
    WARNINGS="${WARNINGS}
⚠️ MANA DEPLETED (0/$MANA_MAX). No magical abilities available. Narrate the hollow feeling of reaching for power and finding nothing."
fi

# Composure depletion
if [ "$COMP_CUR" = "0" ] && [ "$COMP_MAX" != "N/A" ] && [ "$COMP_MAX" != "0" ] 2>/dev/null; then
    WARNINGS="${WARNINGS}
⚠️ COMPOSURE BROKEN (0/$COMP_MAX). Disadvantage on social/PRE rolls. PRE abilities disabled. Character is rattled, shaking, unable to project confidence. Narrate the psychological fracture."
fi

# Build the context injection
cat << CONTEXT
[EMERGENCE RPG STATE REMINDER — from state.json at $STATE_FILE]

CHARACTER: $CHAR_NAME | $CLASS_NAME L$LEVEL | Day $DAY, $TIME
LOCATION: $LOCATION
HP: $HP_CUR/$HP_MAX | Stamina: $STAM_CUR/$STAM_MAX | Mana: $MANA_CUR/$MANA_MAX | Composure: $COMP_CUR/$COMP_MAX
DEF: $PHYS_DEF | Entropy: $ENTROPY

ATTRIBUTES (use these for --stat-score in move CLI):
  MIG: $MIG | AGI: $AGI | FOR: $FOR | PRC: $PRC
  INT: $INT | WIS: $WIS | WIL: $WIL | PRE: $PRE

INVENTORY:
$INVENTORY

CONDITIONS:
$CONDITIONS

ACTIVE CLOCKS:
$CLOCKS
${COMBAT_SECTION}${WARNINGS}

WORKFLOW — EVERY TURN:
1. READ state.json (this hook did it for you — data above is current)
2. Run CLI commands BEFORE narrating any action outcome
3. Narrate based on CLI results — do not invent outcomes
4. WRITE state.json with ALL changes (HP, resources, inventory, time, scene, conditions)
5. End with "What do you do?"
CONTEXT

exit 0
