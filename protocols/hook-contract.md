# Hook Contract

## Goal

Hooks intercept high-risk behavior, record key events, and provide session context.

## Types

| Type | Purpose |
| --- | --- |
| pre-tool | Risk interception before execution |
| post-tool | Audit after execution |
| session | Session startup context |
| prompt | Workflow guidance after user prompt submission |
| delivery | Pre-delivery check |
| maintenance | Update memory, code map, and review report after session end |

## Rules

- Hooks must run locally.
- Hooks must not silently execute destructive operations.
- Blocking hooks must provide a clear reason.
- Hook logs must not store sensitive data.

## Verification

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "scripts/validate-hooks.ps1"
```

Auto-maintenance verification:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "scripts/validate-automation-hooks.ps1"
```

Request routing verification:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "scripts/validate-flow-router.ps1"
```
