---
name: prove-behavior-first
description: Use when new behavior or a fix needs evidence before implementation.
---

# Prove Behavior First

## Core Principle

Prove the target behavior is currently missing or failing before implementation. Without a red signal, the green signal proves nothing.

## Hard Gate

Before implementation, one red evidence type must exist:

1. Automated test failure.
2. Validation script failure.
3. Repeatable command output failure.
4. Explicit manual reproduction scenario with expected difference.

If the project has no test framework, create the smallest runnable check instead of skipping proof.

## Quick Reference

| Scenario | Red Evidence |
| --- | --- |
| New feature | Expected-behavior check fails |
| Bugfix | Regression test or reproduction scenario fails |
| Hook | Hook script fails in standalone run |
| Skill | Pressure scenario or validator fails |
| MCP | Catalog or tool contract check fails |

## Red Flags

- "Test after changing."
- Test passes from the start.
- Failure is a typo or environment issue, not target behavior.
- Only subjective manual validation.
- New behavior has no repeatable evidence.

## Verification

- Red output is recorded.
- The same check passes after implementation.
- Final verification includes relevant full or integration checks.
