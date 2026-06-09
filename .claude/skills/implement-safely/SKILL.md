---
name: implement-safely
description: Use when editing code, configuration, hooks, MCP servers, project skills, or engineering documents.
---

# Implement Safely

## Core Principle

Small scope, verifiable changes, no unrelated modifications. Implementation serves only the currently confirmed goal.

## Hard Gate

Before modifying, satisfy:

1. Confirm task file scope.
2. Read target files before modifying them.
3. Use the smallest viable implementation.
4. Avoid new abstractions unless they remove real duplication or clarify a boundary.
5. Run the corresponding check after each verifiable unit.

Deletion, batch modification, git write operations, production APIs, and destructive database operations require explicit user confirmation first.

## Quick Reference

| Scenario | Action |
| --- | --- |
| Code change | Read target files first, then apply the smallest patch |
| Configuration change | Preserve existing format and default-value semantics |
| Hook change | Ensure standalone execution and visible failures |
| Skill change | Update pressure scenarios and validation together |
| MCP change | Check against `protocols/mcp-contract.md` |

## Red Flags

- Refactoring unauthorized scope because it is nearby.
- Adding abstractions that do not reduce real complexity.
- Modifying files that have not been read.
- Replacing verification with guesses.
- Introducing duplicate protocols, configuration, or entry points.

## Verification

- `git diff` contains only the scope required for this turn.
- Every verifiable unit has a command or check result.
- Can explain the actual KISS, YAGNI, DRY, and SOLID tradeoffs for this turn.
- Unverified items and residual risks are explicitly listed.
