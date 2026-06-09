---
name: shape-design
description: Use when requirements need product, architecture, API, UI, data, or interaction design before implementation.
---

# Shape Design

## Core Principle

Design first converges behavior and boundaries, then enters code. Good design reduces guessing and rework during implementation.

## Hard Gate

Before implementation, clarify:

1. User goal and success criteria.
2. Key constraints: technology, permissions, compatibility, performance, data, UI.
3. At least one rejected option and the reason.
4. Target contract: API, data structure, state machine, hook, or UI interaction.
5. Verification method.

## Quick Reference

| Design Surface | Must Answer |
| --- | --- |
| Product | What task the user completes |
| Architecture | Where the boundary is and who depends on whom |
| API/MCP | Inputs, outputs, errors, permissions |
| UI/Flow | State, entry points, failure feedback |
| Data/Memory | Source of truth, index, retention policy |
| Hooks | Trigger conditions, idempotency, failure handling |

## Red Flags

- Implementation idea exists without success criteria.
- Complex design chosen without comparing alternatives.
- Data source of truth is unclear.
- Hook or MCP has no failure semantics.
- Design has no verification method.

## Verification

- Design can be written to `work/designs/<task-id>.md`.
- Another engineer can write a plan from it.
- Every contract has corresponding verification or review points.
