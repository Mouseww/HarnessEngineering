---
name: plan-work
description: Use when work has multiple steps, touches more than one subsystem, or needs validation before delivery.
---

# Plan Work

## Core Principle

A plan must be executable by another engineer, not merely express intent. A plan is an engineering constraint, not a task list.

## Hard Gate

The plan must include:

1. Goals and non-goals.
2. File scope.
3. Ordered steps.
4. Verification method for each step.
5. Risks and rollback points.

A plan without verification methods must not enter execution.

## Quick Reference

| Item | Passing Standard |
| --- | --- |
| Goal | Acceptable and testable, not aspirational |
| Non-goal | Clear boundaries not to touch |
| Step | Each step can complete in 2 to 10 minutes |
| File scope | Points to concrete directories or files |
| Verification | Each step has a command, check, or review evidence |
| Rollback | Explains undo or stop point |

## Red Flags

- Non-executable phrases such as "handle appropriately", "add tests", or "optimize".
- Plan crosses multiple subsystems without ordering.
- No statement of what is out of scope for this turn.
- No verification command or manual check.
- Plan only restates the user request.

## Verification

- Long tasks are written to `work/active/<task-id>.md`.
- Short tasks may list the plan in the reply, but still require verification methods.
- Before execution, can answer for each step: what to do, where to change, how to prove, and when to stop.
