---
name: diagnose-failure
description: Use when behavior is broken, flaky, slow, failing, or unexplained.
---

# Diagnose Failure

## Core Principle

Reproduce and narrow first, then fix. Evidence-free hypotheses must not enter implementation.

## Hard Gate

Before fixing, complete:

1. Capture the failure symptom: command, log, screenshot, or user-visible behavior.
2. Build a minimal reproduction or explain why reproduction is not possible.
3. List at least two candidate causes.
4. Use evidence to eliminate candidate causes.
5. Map the final cause to a specific code or configuration boundary.

## Quick Reference

| Stage | Artifact |
| --- | --- |
| Reproduce | Failing command or scenario |
| Observe | Logs, errors, status |
| Narrow | Smallest relevant files |
| Hypothesize | Candidate causes |
| Prove | Evidence-backed root cause |
| Fix | Smallest fix |

## Red Flags

- Changing code after seeing the first error.
- Claiming root cause without reproduction.
- Modifying multiple unrelated locations.
- No regression verification.
- Treating symptoms as root cause.

## Verification

- Failure evidence exists before the fix.
- The same scenario passes after the fix.
- Regression checks are added or updated to prevent recurrence.
