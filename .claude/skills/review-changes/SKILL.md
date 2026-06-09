---
name: review-changes
description: Use when changes need review for bugs, regressions, missing tests, unclear contracts, or delivery risk.
---

# Review Changes

## Core Principle

Review finds factual issues that harm delivery first. Style preferences must not masquerade as defects.

## Hard Gate

Before review:

1. Read task goal.
2. Inspect diff or changed files.
3. Check against `protocols/review-contract.md`.
4. Output findings sorted by severity.
5. Give file and line number for each finding.

Issues without file evidence cannot be findings.

## Quick Reference

| Section | Content |
| --- | --- |
| Findings | Defects, regressions, contract breaks, test gaps |
| Open Questions | Unknowns that affect judgment |
| Verification Gaps | Checks not run or impossible to run |
| Change Summary | Secondary summary; do not place before findings |

## Red Flags

- Only saying "looks good".
- No files or line numbers.
- Writing aesthetic preference as a defect.
- Not distinguishing verified and unverified work.
- Ignoring task goal and only doing generic code inspection.

## Verification

- Every finding points to a file and concrete behavior risk.
- If there are no findings, clearly state no issues found and list remaining verification gaps.
- Review output puts findings first.
