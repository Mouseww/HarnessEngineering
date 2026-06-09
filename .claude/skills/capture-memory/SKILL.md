---
name: capture-memory
description: Use when reusable project facts, decisions, repeated failures, conventions, or handoff knowledge should persist beyond the chat.
---

# Capture Memory

## Core Principle

Save reusable facts only, not chat noise. Memory must help the next engineering decision.

## Hard Gate

Before writing memory, confirm:

1. The content is a reusable fact, decision, convention, or repeated failure.
2. Source and scope are clear.
3. Verified facts are separated from inferences.
4. It contains no secrets, tokens, or private data.
5. The path matches its classification.

## Quick Reference

| Type | Path |
| --- | --- |
| Long-lived team standards | `memory/team/` |
| Project facts and decisions | `memory/project/` |
| Agent runtime experience | `memory/agents/<agent-id>/` |
| Searchable index | `memory/index.yaml` |

## Red Flags

- Saving chat transcripts.
- Saving one-off sentiment or temporary preference.
- Missing time, source, or scope.
- Writing inference as fact.
- Including sensitive information.

## Verification

- Record includes time, source, fact, and scope.
- Record is discoverable through `memory/index.yaml` or a relevant index.
- After the auto-maintenance hook runs, memory additions remain readable and traceable.
