---
name: route-request
description: Use when a user request must be classified into an engineering flow before detailed work starts.
---

# Route Request

## Core Principle

Route the request to the right flow before selecting stages and skills. A wrong route accelerates later vibecoding through the wrong process.

## Hard Gate

Before concrete work, obtain:

1. flow: such as `feature-development`, `bugfix`, `incident`, `release`, or `knowledge-capture`.
2. stages: the stages this turn must pass through.
3. skills: every skill must exist at `.claude/skills/<name>/SKILL.md`.
4. artifacts: artifact paths for this turn.
5. next command: executable next command.

## Quick Reference

| Request Signal | Flow |
| --- | --- |
| New capability or behavior change | `feature-development` |
| Error, failure, regression | `bugfix` |
| Production unavailable or alert | `incident` |
| Release, deploy, rollback | `release` |
| Memory, wiki, summary | `knowledge-capture` |
| MCP tool or permission | Add `mcp-governance` |

## Red Flags

- Implementing directly without routing.
- Router outputs a missing skill.
- Bugfix has no diagnosis stage.
- Release has no verification and readiness stage.
- User request mentions MCP, but MCP governance is not included.

## Verification

- Run `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/route-request.ps1 -Prompt "<request>" -Json -NoWrite`.
- Every skill in the route JSON has a corresponding `SKILL.md`.
- `scripts/validate-skills.ps1` covers typical routing prompts.
