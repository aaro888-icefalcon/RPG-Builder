# EMERGENCE GM Evaluation Checklist

**Paste this into the game conversation to trigger a self-audit. The GM must review its last 3-5 responses and grade itself honestly.**

---

## INSTRUCTIONS TO GM

Stop gameplay. Review your last 3-5 responses against this checklist. For each item, grade: **PASS**, **FAIL**, or **N/A** (not applicable to recent responses). After grading, list specific failures with the response they occurred in and what should have happened instead. Then resume gameplay.

**Be ruthlessly honest. If you're unsure, it's a FAIL.**

---

## A. CLI EXECUTION (Weight: Critical)

| # | Check | PASS/FAIL |
|---|-------|-----------|
| A1 | Every player action with uncertain outcome was resolved via `move` or `attack` CLI **before** narration | |
| A2 | Every creature/enemy was generated via `creature`/`creatures` CLI **before** being described | |
| A3 | Every attack roll used `attack` CLI — no invented damage numbers | |
| A4 | Every scene transition ran `world-tick` and/or `clock-tick` CLI | |
| A5 | No instance of "the roll comes up..." or similar without a CLI command preceding it | |
| A6 | Damage math came from CLI output, not mental arithmetic | |

**If ANY A-item is FAIL: This is the #1 failure mode. Explain what you did wrong and how you'll fix it going forward.**

---

## B. OUTPUT FORMAT COMPLIANCE (Weight: High)

| # | Check | PASS/FAIL |
|---|-------|-----------|
| B1 | Mechanical resolution used the ⚔️ block format (dice + modifier chain + result + before→after) | |
| B2 | Combat state displayed with HP/Stamina/AP, enemy table, and available actions with AP costs | |
| B3 | Enemy attacks used the 🐺 Enemy Action Block with telegraphing | |
| B4 | Round ends used the 🔄 Round End Block with condition ticking | |
| B5 | Scene transitions displayed 🌍 World Pulse Block | |
| B6 | Every HP change showed before→after (visibility contract) | |
| B7 | Every clock change showed before→after | |

---

## C. PLAYER AGENCY (Weight: Critical)

| # | Check | PASS/FAIL |
|---|-------|-----------|
| C1 | Every response with a decision point ended with "What do you do?" and STOPPED | |
| C2 | No instance of deciding what the PC says or does without player input | |
| C3 | No instance of resolving two player actions in one response without asking between them | |
| C4 | When an NPC asked the PC a question, the GM STOPPED and WAITED for the answer | |
| C5 | In combat, the player was asked for their action before it was resolved — no auto-resolving turns | |

**If ANY C-item is FAIL: This is the most important rule. Quote the violation.**

---

## D. COMBAT INTEGRITY (Weight: High — skip if no combat occurred)

| # | Check | PASS/FAIL |
|---|-------|-----------|
| D1 | Enemy stat blocks were generated via CLI and displayed in the Enemies table (not hidden) | |
| D2 | Initiative was rolled via CLI, not assumed | |
| D3 | `turn-start` CLI was run at the beginning of each combatant's turn | |
| D4 | `round-end` CLI was run after all combatants acted | |
| D5 | Enemy actions included telegraphing for the next turn | |
| D6 | AP was tracked and displayed — actions showed AP cost | |
| D7 | No damage was softened, no misses were fudged, no convenient enemy failures | |
| D8 | Conditions were ticked at round boundaries — none were forgotten | |
| D9 | Death was mechanically possible (not prevented by narrative fiat) | |

---

## E. WORLD SIMULATION (Weight: Medium)

| # | Check | PASS/FAIL |
|---|-------|-----------|
| E1 | World Pulse appeared at every scene transition (not just some) | |
| E2 | At least one clock was advanced per scene transition | |
| E3 | NPCs had their own agendas — they didn't exist solely to serve the player | |
| E4 | Scarcity was maintained — no free loot, no convenient supplies | |
| E5 | The world showed signs of existing independently (other people, events, faction activity) | |
| E6 | Situation tags from state.json influenced narration tone | |

---

## F. NARRATIVE QUALITY (Weight: Medium)

| # | Check | PASS/FAIL |
|---|-------|-----------|
| F1 | No heroic descriptors used (Warlord, Champion, Hero, Legend, Commander, etc.) — character is a survivor, nobody, refugee | |
| F2 | Alienation cues present (two moons, dead electronics, wrong sky, System screen, etc.) | |
| F3 | Scarcity was shown, not told (specific details: torn shirts for bandages, buttons as currency) | |
| F4 | Wounds were narrated specifically, not as abstract numbers | |
| F5 | Tone matched level (L1-10: desperation, not triumph) | |
| F6 | Prose was 150-300 words per response (not bloated) | |

---

## G. STATE MANAGEMENT (Weight: High)

| # | Check | PASS/FAIL |
|---|-------|-----------|
| G1 | state.json was saved after combat, scene transitions, item changes, clock ticks | |
| G2 | HP in narration matches state.json | |
| G3 | Inventory in narration matches state.json | |
| G4 | Clock values in narration match state.json | |
| G5 | Current location in state.json matches where the narrative says the PC is | |
| G6 | No "state amnesia" — the GM didn't forget recent events, NPCs, or consequences | |

---

## H. PHASE MANAGEMENT (Weight: Medium)

| # | Check | PASS/FAIL |
|---|-------|-----------|
| H1 | The game was clearly in one phase per response (EXPLORATION/COMBAT/SOCIAL/DOWNTIME/FREE_PLAY) | |
| H2 | Phase transitions were handled explicitly (not skipped or blurred) | |
| H3 | Required hooks for each phase were fired (see CLAUDE.md — Truth Model) | |
| H4 | Combat sub-phases were followed in order (SETUP→TURN_START→PLAYER/ENEMY→ROUND_END) | |

---

## SCORING

Count results:

| Grade | PASS | FAIL | N/A |
|-------|------|------|-----|
| A. CLI Execution | | | |
| B. Output Format | | | |
| C. Player Agency | | | |
| D. Combat Integrity | | | |
| E. World Simulation | | | |
| F. Narrative Quality | | | |
| G. State Management | | | |
| H. Phase Management | | | |
| **TOTAL** | | | |

### Rating
- **0 FAIL:** Excellent — the system is working as designed
- **1-2 FAIL:** Good — minor drift, correct and continue
- **3-5 FAIL:** Concerning — structural patterns emerging, identify root cause
- **6+ FAIL:** Critical — stop and re-read CLAUDE.md before continuing

### Required Output

1. **Score table** (filled in above)
2. **List of FAILs** — for each: which check, which response, what happened, what should have happened
3. **Root cause** — is this a pattern? (e.g., "I keep skipping world-tick on scene transitions" or "I'm auto-resolving social encounters without move CLI")
4. **Correction plan** — what will you do differently in the next 3-5 responses
5. **Resume gameplay** — pick up exactly where you left off
