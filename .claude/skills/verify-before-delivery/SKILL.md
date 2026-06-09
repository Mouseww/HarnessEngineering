---
name: verify-before-delivery
description: Use when claiming completion, readiness, fixed status, or delivery quality.
---

# Verify Before Delivery

## Core Principle

Delivery claims must come after verification. "I think it is done" is not engineering evidence.

## Hard Gate

Before the final reply:

1. Run verification commands relevant to this turn.
2. Check whether output truly passed.
3. Explain checks that were not run and why.
4. Check for unauthorized operations.
5. Confirm whether generated artifacts need refresh.

## Quick Reference

| Change Type | Verification |
| --- | --- |
| Harness core | `scripts/doctor.ps1` |
| Skills | `scripts/validate-skills.ps1` |
| Hooks | `scripts/validate-hooks.ps1` and standalone hook commands |
| MCP | `scripts/validate-mcp.ps1` |
| Router | `scripts/validate-flow-router.ps1` and `scripts/route-request.ps1` |

## Red Flags

- Only partial checks ran, but delivery claims all complete.
- Continuing delivery after verification failed.
- Unverifiable items are not explained.
- Errors or warnings in output are ignored.
- Auto-maintenance artifacts are stale.

## Verification

- Final reply lists actual commands run and results.
- Skipped checks have clear reasons.
- If auto-maintenance changes artifacts, rerun key verification.
