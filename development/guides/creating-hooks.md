# Creating Claude Code Hooks for Your Game

Hooks are shell scripts that execute automatically at specific points in the Claude Code lifecycle. They are the **Tier 1 enforcement layer** — mechanical guardrails that prevent rule violations that advisory instructions alone cannot guarantee.

## Why Hooks Matter for AI RPGs

AI game masters drift. They forget rules, skip validation, improvise mechanics, and lose track of game state as the context window grows. Hooks solve this by intercepting tool calls and responses at four lifecycle points and either injecting corrective context or blocking invalid behavior.

## Hook Lifecycle Points

| Event | When it fires | What it can do |
|---|---|---|
| `UserPromptSubmit` | Player sends a message | Inject context (state summary, lore reminders) |
| `PreToolUse` | Before a tool executes | Block invalid writes (exit 2 + stderr) |
| `PostToolUse` | After a tool completes | Inject context from tool output |
| `Stop` | When Claude finishes responding | Block and force retry (exit 0 + JSON) |

## Hook Registration

Hooks are registered in `.claude/settings.json`:

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash \"$CLAUDE_PROJECT_DIR\"/.claude/hooks/your-hook.sh"
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"$CLAUDE_PROJECT_DIR\"/.claude/hooks/validate-state-write.sh"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash \"$CLAUDE_PROJECT_DIR\"/.claude/hooks/validate-response.sh"
          }
        ]
      }
    ]
  }
}
```

## Hook Input/Output Contracts

Every hook receives JSON on stdin with context fields:

```json
{
  "cwd": "/path/to/project",
  "transcript_path": "/path/to/transcript.jsonl",
  "tool_input": { ... },
  "tool_output": "...",
  "stop_hook_active": false
}
```

### Return values by event type

**UserPromptSubmit** — stdout text is injected as context:
```bash
echo "[STATE REMINDER] HP: 5/20, Day 3, Location: Market"
exit 0
```

**PreToolUse** — exit 0 allows, exit 2 blocks:
```bash
echo "BLOCKED: HP exceeds max. Fix before saving." >&2
exit 2
```

**Stop** — JSON with `decision: "block"` forces retry:
```bash
echo '{"decision": "block", "reason": "Missing required format element."}'
exit 0
```

## Recommended Hooks by Category

### 1. State Context Injection (UserPromptSubmit)

**Purpose:** Fight context decay by re-injecting current game state every turn.

**What to extract from state.json:**
- Character name, level, resource pools (HP, etc.)
- Current location, time of day
- Active conditions/effects
- Active clocks with progress
- Combat state if in combat

**Pattern:**
```bash
STATE_FILE=$(find "$PROJECT_DIR/campaigns" -name "state.json" -maxdepth 2 | head -1)
if [ -z "$STATE_FILE" ]; then exit 0; fi

HP_CUR=$(cat "$STATE_FILE" | jq -r '.character.hp.current')
HP_MAX=$(cat "$STATE_FILE" | jq -r '.character.hp.max')
# ... extract more fields
echo "[STATE] HP: $HP_CUR/$HP_MAX | Location: $LOCATION"
```

### 2. State Write Validation (PreToolUse, matcher: Write|Edit)

**Purpose:** Block writes to state.json that would corrupt game state.

**What to check:**
- Valid JSON syntax
- Required top-level keys present
- Resource pools don't exceed max
- Clock values in range
- No forbidden obsolete keys

### 3. Response Format Validation (Stop)

**Purpose:** Ensure the GM response follows your game's format requirements.

**Common checks:**
- Player prompt present ("What do you do?")
- Combat display format when in combat
- CLI was called before narrating action outcomes
- Forced consequences were narrated
- No auto-resolving player dialogue

**Infinite loop prevention:** Always check `stop_hook_active`:
```bash
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then exit 0; fi
```

### 4. CLI Output Parsing (PostToolUse, matcher: Bash)

**Purpose:** Parse CLI output and inject command-specific enforcement.

**Pattern:**
```bash
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
if ! echo "$COMMAND" | grep -q "your_cli"; then exit 0; fi

TOOL_OUTPUT=$(echo "$INPUT" | jq -r '.tool_output // empty')
# Parse output and build enforcement context
echo "{\"additionalContext\": \"Use EXACT values from CLI output.\"}"
```

## Implementation Checklist

1. Create the hook script in `.claude/hooks/`
2. Make it executable: `chmod +x .claude/hooks/your-hook.sh`
3. Register it in `.claude/settings.json` under the correct event
4. Test with a gameplay turn to verify it fires
5. Document the hook in your phase 6 validation skills

## Design Principles

- **Fail open for non-RPG sessions:** Check for campaign directory or RPG indicators before applying game-specific enforcement.
- **Keep hooks fast:** They run on every turn. Avoid expensive operations.
- **Use jq for JSON parsing:** It's the standard tool for hook scripts.
- **Prevent infinite loops in Stop hooks:** Always check `stop_hook_active`.
- **One responsibility per hook:** Easier to debug and maintain.
