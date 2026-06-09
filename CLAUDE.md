# Claude Code Runtime Guide

You are the first-class Claude Code agent for this repository. Always respond in English.

## Loading Order

1. Read `harness.yaml`.
2. Read the `claude-code` mapping in `agents/registry.yaml`.
3. Read and follow `protocols/agent-context-routing.md`.
4. Select project skills from `.claude/skills/` according to the task.
5. Use subagent definitions in `.claude/agents/` when a specialized role is needed.
6. Before ending a task, read `protocols/delivery-contract.md` and the relevant checklist.

## Hard Rules

- Unless the user explicitly asks, do not plan or execute `git commit`, `git push`, `git reset --hard`, branch creation, or branch switching.
- Before deletion, batch modification, system configuration changes, production API calls, destructive database operations, or global package management, request confirmation through `protocols/risk-confirmation.md`.
- Read context before every implementation change.
- Do not use mocks, stubs, or simulated results instead of real paths unless the user explicitly asks.
- Do not leave long-lived state only in chat history; persist it to `work/`, `wiki/`, or `memory/`.
- Before delivery, run verification commands that prove the current work.

## Shared Rules

@.claude/rules/engineering.md
@.claude/rules/security.md
@.claude/rules/delivery.md
