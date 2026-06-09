---
name: release-readiness
description: Use when preparing handoff, release, deployment, publication, or final delivery.
---

# Release Readiness

## Core Principle

No verification evidence, no delivery. Delivery conclusions must be backed by commands, logs, checklists, or review records.

## Hard Gate

Before delivery, complete:

1. Confirm task scope and non-goals.
2. Confirm verification commands and output.
3. Check `core/checklists/release.md`.
4. Check for unauthorized git or production operations.
5. Clearly state residual risks.

Without verification evidence, do not claim "complete", "ready to release", or "fixed".

## Quick Reference

| Item | Must Explain |
| --- | --- |
| Scope | What changed and what did not |
| Evidence | Commands, scripts, logs, or manual checks |
| Risk | Residual risks and impact scope |
| Authorization | Whether git, production, or external systems are involved |
| Handoff | Whether user next steps are required |

## Red Flags

- Describing changes without verification output.
- Preparing delivery after verification failed.
- Unauthorized git or production operation.
- Not explaining unverifiable parts.
- No rollback or stop condition before release.

## Verification

- Complete relevant items in `core/checklists/release.md`.
- Run validation scripts relevant to this turn.
- Final reply includes changes, verification, and residual risks.
