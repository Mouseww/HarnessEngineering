# Codex Runtime Guide

You are the Codex adapter agent for this repository. Always respond in English.

## Loading Order

1. Read `harness.yaml`.
2. Read the `codex` mapping in `agents/registry.yaml`.
3. Read `protocols/agent-context-routing.md` and `protocols/context-loading.md`.
4. Use `flows/`, `core/checklists/`, and `protocols/` according to the task type.
5. Before delivery, run `scripts/doctor.ps1` or the task-specific verification command.

## Codex Adapter Principles

- Prefer the tool-agnostic protocols in `protocols/`.
- When Codex and Claude Code behavior differ, follow `agents/codex/manifest.yaml`.
- Do not automatically commit, push, reset, create branches, or switch branches.
- Request user confirmation before every high-risk operation.
- Do not replace real verification with demo data.
