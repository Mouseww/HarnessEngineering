---
name: handle-review-feedback
description: Use when review comments, requested changes, or critique must be triaged before edits.
---

# Handle Review Feedback

## Core Principle

Classify and verify review feedback before modifying. Not every suggestion should be implemented directly.

## Hard Gate

Before handling feedback:

1. List each feedback item.
2. Classify as bug, risk, test gap, clarification, style, or non-actionable.
3. Decide whether it is related to the task goal.
4. Write a handling plan for actionable items.
5. Give factual reasons for rejected items.

## Quick Reference

| Type | Action |
| --- | --- |
| Bug | Reproduce, fix, and verify regression |
| Risk | Add constraint or verification |
| Test gap | Add a red check or validation first |
| Clarification | Update explanation or contract |
| Style | Handle only when aligned with project standards |
| Non-actionable | Explain why it is not handled |

## Red Flags

- Changing without reading feedback context.
- Accepting everything and expanding scope.
- Rejecting feedback without evidence.
- Not re-verifying after modification.
- Ignoring test gaps raised by the reviewer.

## Verification

- Every feedback item has handling status.
- Corresponding verification runs after actionable items are completed.
- Final notes state what was accepted, what was rejected, and why.
