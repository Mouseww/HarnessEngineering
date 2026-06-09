---
name: request-review
description: Use when completed changes need an independent engineering review before handoff or merge.
---

# Request Review

## Core Principle

Major or high-risk changes need independent review before delivery. A review request must provide enough context and verification evidence.

## Hard Gate

Before requesting review, prepare:

1. Task goal and non-goals.
2. Change scope.
3. Key design tradeoffs.
4. Verification already run.
5. Risks the reviewer should focus on.

## Quick Reference

| Review Input | Content |
| --- | --- |
| Goal | User goal |
| Scope | Files and modules |
| Risk | Contracts, data, permissions, regressions |
| Evidence | Commands and results |
| Ask | Specific questions for review |

## Red Flags

- Only saying "please take a look".
- No verification evidence.
- High-risk boundaries are not explained.
- Obvious failed checks remain before review request.
- Treating review as a replacement for verification.

## Verification

- The review request lets the reviewer proceed without asking for basic context.
- If findings are received, enter `handle-review-feedback`.
- If review is not available, state residual risk during delivery.
