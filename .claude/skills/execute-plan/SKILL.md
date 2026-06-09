---
name: execute-plan
description: Use when an approved implementation plan is ready to be carried out in the current workspace.
---

# Execute Plan

## Core Principle

Execute the plan step by step, verifying and updating status after each step. Execution is not improvisation.

## Hard Gate

Execution requires an actionable plan. During execution:

1. Work on one step at a time.
2. Read target files before modifying them.
3. Run the corresponding verification after each completed step.
4. Record the reason for any plan deviation.
5. Request confirmation before high-risk operations.

## Quick Reference

| Status | Behavior |
| --- | --- |
| Pending | Not started |
| In progress | The only current execution step |
| Done | Has verification evidence |
| Blocked | States blocker and required input |
| Changed | Records why the original plan changed |

## Red Flags

- Multiple steps proceed at once and scope drifts.
- Marking complete without verification.
- Expanding implementation directly after discovering a new requirement.
- The plan no longer applies but is not updated.
- High-risk operation is not confirmed.

## Verification

- Status in `work/active/<task-id>.md` or the reply matches reality.
- Every completed step has evidence.
- Final diff matches plan scope; deviations are explained.
