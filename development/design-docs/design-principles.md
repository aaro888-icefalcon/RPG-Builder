# Design Principles for Claude Code Development

These principles govern how the repository's Claude Code configuration is structured and maintained. They complement the operational rules in `CLAUDE.md` with higher-level philosophy about *how we configure the development environment itself*.

## 1) Map, Not Manual

CLAUDE.md files should be short entry points that orient and point to deeper sources — not exhaustive instruction manuals.

- Root `CLAUDE.md` selects the operating mode and links to surfaces.
- Subtree CLAUDE.md files (e.g., `runtime/CLAUDE.md`) define scope-specific rules and reference deeper docs.
- Detailed guidance belongs in referenced documents, not inline in CLAUDE.md.

**Why this matters:** Every CLAUDE.md loads into the context window. Bloated files waste context budget and dilute the signal of critical rules. Keep them tight; let Claude read deeper when it needs to.

## 2) Enforcement Hierarchy

Not all directives carry the same weight. The repo uses three tiers:

| Tier | Mechanism | Behavior | Examples |
|------|-----------|----------|----------|
| **Enforced** | `.claude/settings.json` hooks, permission deny rules | Mechanically blocked — Claude cannot bypass | State-write validation, combat-state checks, `rm -rf` denial |
| **Advisory-persistent** | CLAUDE.md, `.claude/rules/` | Loaded into every session, followed by convention | Plan-first workflow, scope limits, durable truth policy |
| **Ephemeral** | Conversation-only decisions | Lost when the session ends | Ad-hoc clarifications, one-off instructions |

**Placement rule:** If a rule *must not* be violated, it belongs in a hook or deny rule (Tier 1). If it guides behavior but occasional deviation is acceptable, it belongs in CLAUDE.md or rules files (Tier 2). If it's decided in conversation, it must be persisted to Tier 2 before the session ends (per the durable truth policy).

## 3) Single Canonical Home

Every directive lives in exactly one place. Other files may *reference* it with a pointer, but must not *duplicate* it.

- If the same rule appears in multiple CLAUDE.md files, consolidate to the canonical scope and add a pointer from the other.
- If a hook enforces a rule that is also stated in CLAUDE.md, the hook is the canonical enforcement; the CLAUDE.md entry is the human-readable description.
- When updating a rule, update it at the canonical source. Pointers don't need editing.

**Why this matters:** Duplicated rules drift apart over time. When two files disagree, developers waste time figuring out which one is authoritative.

## 4) Dual-Mode Separation

Development mode and runtime (play) mode have independent governance.

- Root `CLAUDE.md` governs development.
- `runtime/CLAUDE.md` governs play.
- A change to development workflow does not automatically apply to runtime, and vice versa.
- Shared principles (e.g., determinism) are stated in both but scoped to their mode's concerns.

**Why this matters:** Runtime mode is intentionally stricter (no silent repairs, 8-step turn protocol, forced consequences). Development mode allows more flexibility (exploration, refactoring, docs changes). Mixing them dilutes the strictness where it matters most.

## 5) Configuration Placement Guide

When adding a new directive, use this decision tree:

```
Is this rule critical enough that violation would corrupt game state or be irreversible?
  YES → Add a hook in .claude/hooks/ and register in settings.json
  NO  ↓

Does this rule apply to a specific subtree (e.g., scripts/, references/)?
  YES → Add to that subtree's CLAUDE.md
  NO  ↓

Is this a general development practice?
  YES → Add to root CLAUDE.md (if short) or a .claude/rules/ file (if detailed)
  NO  ↓

Is this a design decision or architectural rationale?
  YES → Add to design-docs/ (this directory)
```

For placing *content files* (mechanics, lore, tables, templates) rather than directives, see [repo-maintenance-policy.md](../repo-maintenance-policy.md) §1.

## 6) Navigation File Conventions — Rationale

The three navigation file types and their operative definitions are in root `CLAUDE.md` §File Conventions. This section explains the governance decisions behind them.

**Migration note:** The repository historically used `README.md` and `START-HERE.md` for navigation. These have been consolidated into `index.md`. The root `README.md` is retained as the GitHub landing page.

**Why three, not five:** README.md and START-HERE.md both answer "what's here and where do I go?" — the same question `index.md` answers. Having three conventions for one role means nobody knows which to create, update, or trust. One convention eliminates the ambiguity.

**Why AGENTS.md is conditional:** Claude Code loads AGENTS.md for subagent tasks (the Task tool). If the subagent rules are identical to the main session rules in CLAUDE.md, AGENTS.md adds nothing but a maintenance burden and duplication risk. Create AGENTS.md only when subagents need different constraints (e.g., stricter scope limits, different approval gates, restricted tool access).

## 7) Progressive Expansion

The `.claude/` directory supports additional configuration surfaces beyond what the repo currently uses:

| Surface | Purpose | Current status | Add when... |
|---------|---------|---------------|-------------|
| `hooks/` | Mechanically enforced validation gates | **Active** (11 scripts) | A rule must be enforced, not just advised |
| `rules/` | Modular auto-loaded rule files | Not yet used | CLAUDE.md grows too large, or domain-scoped rules emerge |
| `skills/` | Reusable multi-step workflow templates | Not yet used | A workflow is repeated 3+ times across sessions |
| `agents/` | Specialized subagent definitions | Not yet used | A focused task pattern (auditing, balance-checking) recurs |

**Principle:** Don't add configuration surfaces preemptively. Add them when a concrete, repeated pattern justifies the maintenance cost. One clear CLAUDE.md entry is better than an over-engineered multi-file setup that nobody updates.
