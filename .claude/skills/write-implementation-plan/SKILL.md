---
name: write-implementation-plan
description: Use when accepted design or requirements need an actionable implementation plan.
---

# Write Implementation Plan

## Core Principle

An implementation plan must split design into executable, verifiable, stoppable small steps. Plans must not hide risk.

## Hard Gate

The plan must include:

1. Scope and non-scope.
2. Files or directories to change.
3. Ordered steps.
4. Expected output for each step.
5. Verification for each step.
6. Risks, rollback points, and operations requiring user confirmation.

## Quick Reference

| Plan Field | Passing Standard |
| --- | --- |
| Scope | Acceptable and testable |
| Files | Concrete paths |
| Steps | Each step under 10 minutes |
| Verify | Command or check |
| Risk | Impact scope and stop condition |
| Handoff | Next executor can take over |

## Red Flags

- Step is written as "implement feature".
- Current goal and future goal are not separated.
- Verification is only at the end with no per-step evidence.
- Risk only says "low risk".
- Reader must guess file scope again.

## Verification

- Plan is written to `work/plans/<task-id>.md` or a short-task reply.
- The plan can enter `execute-plan` directly.
- User or executor can mark completion step by step.
