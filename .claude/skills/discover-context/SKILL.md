---
name: discover-context
description: Use when starting work in a repository, resuming a task, entering an unfamiliar module, or before modifying files.
---

# Discover Context

## Core Principle

Build citeable factual context before designing, planning, or modifying. Old chat, model memory, and a single search result are not current sources of truth.

## Hard Gate

Before entering design or file modification, complete:

1. Read `harness.yaml` and `agents/registry.yaml`.
2. Read `protocols/context-loading.md`.
3. Check whether `work/active/` contains a current task.
4. Check relevant `wiki/`, `memory/project/`, and `memory/team/` content.
5. Use `rg` to find related code, documents, or protocols.
6. Output current understanding, unknowns, and next step.

If any item is missing, continue context gathering only. Do not start implementation.

## Quick Reference

| Question | Passing Standard |
| --- | --- |
| What is the goal? | Can describe it in one sentence |
| What changes? | Has concrete files or directories |
| What is the risk? | Lists at least one verification risk |
| How is it proven? | Has a command or checklist |
| Current task | Knows whether `work/active/` already has an active task |

## Red Flags

- The user says "just change it", but protocols and target files have not been read.
- Module responsibility is guessed from file names only.
- Old memory is treated as current repository fact.
- Search stops after one `rg` result.
- Implementation is about to start without knowing the verification command.

## Verification

- Can list the context files read.
- Can explain what is in and out of scope for this turn.
- Can identify at least one risk and its verification method.
- If context is insufficient, can state the blocker instead of guessing.
